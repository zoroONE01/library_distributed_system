package distributed

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/pkg/database"
	"log"
)

// TwoPhaseCommitCoordinator handles distributed transactions using 2PC protocol
type TwoPhaseCommitCoordinator struct {
	config *config.Config
	pool   *database.ConnectionPool
}

// TransactionParticipant represents a site participating in distributed transaction
type TransactionParticipant struct {
	SiteID     string
	Connection *sql.DB
	Prepared   bool
	Committed  bool
	Aborted    bool
}

// DistributedTransaction represents a distributed transaction
type DistributedTransaction struct {
	ID           string
	Participants map[string]*TransactionParticipant
	Status       string // PREPARING, PREPARED, COMMITTING, COMMITTED, ABORTING, ABORTED
}

func NewTwoPhaseCommitCoordinator(config *config.Config) *TwoPhaseCommitCoordinator {
	return &TwoPhaseCommitCoordinator{
		config: config,
		pool:   database.GetPool(),
	}
}

// TransferBook implements distributed book transfer between sites using 2PC
// This is the academic demonstration of distributed transaction as required
func (c *TwoPhaseCommitCoordinator) TransferBook(maQuyenSach, fromSite, toSite string) error {
	log.Printf("Starting 2PC transaction for book transfer: %s from %s to %s", maQuyenSach, fromSite, toSite)

	// Create distributed transaction
	txn := &DistributedTransaction{
		ID:           fmt.Sprintf("transfer_%s_%s_to_%s", maQuyenSach, fromSite, toSite),
		Participants: make(map[string]*TransactionParticipant),
		Status:       "PREPARING",
	}

	// Get connections to both sites
	fromConn, err := c.pool.GetConnection(fromSite, c.config.GetConnectionString(fromSite))
	if err != nil {
		return fmt.Errorf("failed to connect to source site %s: %w", fromSite, err)
	}

	toConn, err := c.pool.GetConnection(toSite, c.config.GetConnectionString(toSite))
	if err != nil {
		return fmt.Errorf("failed to connect to destination site %s: %w", toSite, err)
	}

	// Add participants
	txn.Participants[fromSite] = &TransactionParticipant{
		SiteID:     fromSite,
		Connection: fromConn,
	}
	txn.Participants[toSite] = &TransactionParticipant{
		SiteID:     toSite,
		Connection: toConn,
	}

	// Phase 1: PREPARE
	if err := c.preparePhase(txn, maQuyenSach, fromSite, toSite); err != nil {
		log.Printf("Prepare phase failed: %v", err)
		c.abortTransaction(txn)
		return err
	}

	// Phase 2: COMMIT
	if err := c.commitPhase(txn); err != nil {
		log.Printf("Commit phase failed: %v", err)
		c.abortTransaction(txn)
		return err
	}

	log.Printf("2PC transaction completed successfully for book transfer: %s", maQuyenSach)
	return nil
}

// preparePhase implements Phase 1 of 2PC protocol
func (c *TwoPhaseCommitCoordinator) preparePhase(txn *DistributedTransaction, maQuyenSach, fromSite, toSite string) error {
	log.Printf("Phase 1: PREPARE - Transaction ID: %s", txn.ID)

	// Prepare source site (delete operation)
	fromParticipant := txn.Participants[fromSite]
	if err := c.prepareDelete(fromParticipant, maQuyenSach); err != nil {
		return fmt.Errorf("failed to prepare delete at source site %s: %w", fromSite, err)
	}
	fromParticipant.Prepared = true

	// Prepare destination site (insert operation)
	toParticipant := txn.Participants[toSite]
	if err := c.prepareInsert(toParticipant, maQuyenSach, toSite); err != nil {
		return fmt.Errorf("failed to prepare insert at destination site %s: %w", toSite, err)
	}
	toParticipant.Prepared = true

	txn.Status = "PREPARED"
	log.Printf("Phase 1 completed: All participants prepared for transaction %s", txn.ID)
	return nil
}

// CreateSachDistributed creates a book using 2PC across all sites (for replicated table)
func (c *TwoPhaseCommitCoordinator) CreateSachDistributed(isbn, tenSach, tacGia, transactionID string) error {
	log.Printf("Starting 2PC transaction for book creation: %s", isbn)

	// Create distributed transaction
	txn := &DistributedTransaction{
		ID:           transactionID,
		Participants: make(map[string]*TransactionParticipant),
		Status:       "PREPARING",
	}

	// Get connections to all sites
	for _, site := range c.config.Sites {
		conn, err := c.pool.GetConnection(site.SiteID, c.config.GetConnectionString(site.SiteID))
		if err != nil {
			return fmt.Errorf("failed to connect to site %s: %w", site.SiteID, err)
		}

		txn.Participants[site.SiteID] = &TransactionParticipant{
			SiteID:     site.SiteID,
			Connection: conn,
		}
	}

	// Phase 1: PREPARE - Call sp_QuanLy_PrepareCreateSach on all sites
	if err := c.prepareSachCreation(txn, isbn, tenSach, tacGia, transactionID); err != nil {
		log.Printf("Prepare phase failed for book creation: %v", err)
		c.abortSachCreation(txn, transactionID)
		return err
	}

	// Phase 2: COMMIT - Call sp_QuanLy_CommitCreateSach on all sites
	if err := c.commitSachCreation(txn, isbn, tenSach, tacGia, transactionID); err != nil {
		log.Printf("Commit phase failed for book creation: %v", err)
		c.abortSachCreation(txn, transactionID)
		return err
	}

	log.Printf("2PC transaction completed successfully for book creation: %s", isbn)
	return nil
}

// prepareSachCreation implements Phase 1 for book creation
func (c *TwoPhaseCommitCoordinator) prepareSachCreation(txn *DistributedTransaction, isbn, tenSach, tacGia, transactionID string) error {
	log.Printf("Phase 1: PREPARE - Book Creation Transaction ID: %s", transactionID)

	for siteID, participant := range txn.Participants {
		// Call sp_QuanLy_PrepareCreateSach
		query := "EXEC sp_QuanLy_PrepareCreateSach @ISBN = ?, @TenSach = ?, @TacGia = ?, @TransactionId = ?"
		_, err := participant.Connection.Exec(query, isbn, tenSach, tacGia, transactionID)
		if err != nil {
			return fmt.Errorf("failed to prepare book creation at site %s: %w", siteID, err)
		}
		participant.Prepared = true
		log.Printf("Site %s prepared for book creation", siteID)
	}

	txn.Status = "PREPARED"
	log.Printf("Phase 1 completed: All sites prepared for book creation %s", isbn)
	return nil
}

// commitSachCreation implements Phase 2 for book creation
func (c *TwoPhaseCommitCoordinator) commitSachCreation(txn *DistributedTransaction, isbn, tenSach, tacGia, transactionID string) error {
	log.Printf("Phase 2: COMMIT - Book Creation Transaction ID: %s", transactionID)

	for siteID, participant := range txn.Participants {
		if !participant.Prepared {
			return fmt.Errorf("site %s was not prepared, cannot commit", siteID)
		}

		// Call sp_QuanLy_CommitCreateSach
		query := "EXEC sp_QuanLy_CommitCreateSach @ISBN = ?, @TenSach = ?, @TacGia = ?, @TransactionId = ?"
		_, err := participant.Connection.Exec(query, isbn, tenSach, tacGia, transactionID)
		if err != nil {
			return fmt.Errorf("failed to commit book creation at site %s: %w", siteID, err)
		}
		participant.Committed = true
		log.Printf("Site %s committed book creation", siteID)
	}

	txn.Status = "COMMITTED"
	log.Printf("Phase 2 completed: Book creation committed on all sites for %s", isbn)
	return nil
}

// abortSachCreation rolls back book creation on all sites
func (c *TwoPhaseCommitCoordinator) abortSachCreation(txn *DistributedTransaction, transactionID string) {
	log.Printf("Aborting book creation transaction: %s", transactionID)

	for siteID, participant := range txn.Participants {
		// Call rollback stored procedure if exists
		query := "EXEC sp_QuanLy_RollbackCreateSach @TransactionId = ?"
		_, err := participant.Connection.Exec(query, transactionID)
		if err != nil {
			log.Printf("Warning: Failed to rollback book creation at site %s: %v", siteID, err)
		} else {
			log.Printf("Site %s rolled back book creation", siteID)
		}
		participant.Aborted = true
	}

	txn.Status = "ABORTED"
}

// commitPhase implements Phase 2 of 2PC protocol for book transfer
func (c *TwoPhaseCommitCoordinator) commitPhase(txn *DistributedTransaction) error {
	log.Printf("Phase 2: COMMIT - Transaction ID: %s", txn.ID)
	txn.Status = "COMMITTING"

	// Commit all participants
	for siteID, participant := range txn.Participants {
		if err := c.commitParticipant(participant); err != nil {
			log.Printf("Failed to commit participant %s: %v", siteID, err)
			// In a real system, we would need to handle partial failures
			return err
		}
		participant.Committed = true
		log.Printf("Participant %s committed successfully", siteID)
	}

	txn.Status = "COMMITTED"
	log.Printf("Phase 2 completed: All participants committed")
	return nil
}

// commitParticipant commits changes at a participant site
func (c *TwoPhaseCommitCoordinator) commitParticipant(participant *TransactionParticipant) error {
	_, err := participant.Connection.Exec("COMMIT TRANSACTION")
	return err
}

// abortTransaction aborts the distributed transaction
func (c *TwoPhaseCommitCoordinator) abortTransaction(txn *DistributedTransaction) {
	log.Printf("Aborting transaction: %s", txn.ID)
	txn.Status = "ABORTING"

	for siteID, participant := range txn.Participants {
		if err := c.abortParticipant(participant); err != nil {
			log.Printf("Failed to abort participant %s: %v", siteID, err)
		} else {
			participant.Aborted = true
			log.Printf("Participant %s aborted successfully", siteID)
		}
	}

	txn.Status = "ABORTED"
}

// abortParticipant aborts changes at a participant site
func (c *TwoPhaseCommitCoordinator) abortParticipant(participant *TransactionParticipant) error {
	_, err := participant.Connection.Exec("ROLLBACK TRANSACTION")
	return err
}

// prepareDelete prepares deletion of book from source site
func (c *TwoPhaseCommitCoordinator) prepareDelete(participant *TransactionParticipant, maQuyenSach string) error {
	// Verify book exists and can be deleted
	var count int
	err := participant.Connection.QueryRow(
		"SELECT COUNT(*) FROM QUYENSACH WHERE MaQuyenSach = ? AND TinhTrang = N'Có sẵn'",
		maQuyenSach).Scan(&count)
	if err != nil {
		return err
	}

	if count == 0 {
		return fmt.Errorf("book %s not available for transfer", maQuyenSach)
	}

	// Prepare to delete (lock the record)
	_, err = participant.Connection.Exec(
		"UPDATE QUYENSACH SET TinhTrang = N'Đang chuyển' WHERE MaQuyenSach = ?",
		maQuyenSach)

	return err
}

// prepareInsert prepares insertion of book at destination site
func (c *TwoPhaseCommitCoordinator) prepareInsert(participant *TransactionParticipant, maQuyenSach, toSite string) error {
	// Get book details from source to prepare insert
	// For now, we assume the book details are available
	// In a real implementation, we would retrieve these from the source
	log.Printf("Destination site %s prepared for book copy insertion", toSite)
	return nil
}

// TransferBookUsingStoredProcedure uses the existing stored procedure approach
// This calls the sp_ChuyenSach stored procedure which already implements 2PC
func (c *TwoPhaseCommitCoordinator) TransferBookUsingStoredProcedure(maQuyenSach, fromSite, toSite string) error {
	log.Printf("Using stored procedure for book transfer: %s from %s to %s", maQuyenSach, fromSite, toSite)

	// Execute from the source site
	conn, err := c.pool.GetConnection(fromSite, c.config.GetConnectionString(fromSite))
	if err != nil {
		return fmt.Errorf("failed to connect to source site %s: %w", fromSite, err)
	}

	// Call the stored procedure which handles 2PC internally
	_, err = conn.Exec("EXEC sp_ChuyenSach @MaQuyenSach = ?, @TuChiNhanh = ?, @DenChiNhanh = ?",
		maQuyenSach, fromSite, toSite)
	if err != nil {
		return fmt.Errorf("failed to transfer book using stored procedure: %w", err)
	}

	log.Printf("Book transfer completed successfully using stored procedure")
	return nil
}
