package repository

import (
	"context"
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
	"log"
	"time"
)

// BorrowRepository handles borrow operations using raw SQL queries
type BorrowRepository struct {
	*BaseRepository
	siteID string // Current site for this repository instance
}

// BorrowRepositoryInterface defines borrow-related operations with raw SQL
type BorrowRepositoryInterface interface {
	// Core borrow operations (FR2, FR3)
	CreateBorrow(ctx context.Context, borrow *models.PhieuMuon, userSite string) error
	ReturnBook(ctx context.Context, maQuyenSach string, userSite string) error
	GetBorrowByID(ctx context.Context, maPM int) (*models.PhieuMuon, error)
	GetBorrowsBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.PhieuMuon, int, error)

	// Advanced borrow operations
	GetActiveBorrowsByReader(ctx context.Context, maDG string) ([]*models.PhieuMuon, error)
	GetBorrowHistory(ctx context.Context, maDG string, pagination *utils.PaginationParams) ([]*models.PhieuMuon, int, error)
	GetOverdueBooks(ctx context.Context, siteID string) ([]*models.BorrowRecordWithDetails, error)
	GetBorrowRecordsWithDetails(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.BorrowRecordWithDetails, int, error)

	// Validation operations
	CanBorrowBook(ctx context.Context, maDG, maQuyenSach, siteID string) error
	GetActiveBookCopy(ctx context.Context, maQuyenSach string) (*models.QuyenSach, error)

	// Statistics
	GetBorrowStatistics(ctx context.Context, siteID string) (map[string]interface{}, error)
	GetPopularBooks(ctx context.Context, siteID string, limit int) ([]*models.BookWithAvailability, error)
}

// NewBorrowRepository creates a new borrow repository with raw SQL
func NewBorrowRepository(config *config.Config, siteID string) BorrowRepositoryInterface {
	return &BorrowRepository{
		BaseRepository: NewBaseRepository(config),
		siteID:         siteID,
	}
}

// CreateBorrow creates a new borrow record with validation (FR2)
func (r *BorrowRepository) CreateBorrow(ctx context.Context, borrow *models.PhieuMuon, userSite string) error {
	// Authorization: only allow creation in user's site
	if borrow.MaCN != userSite {
		return fmt.Errorf("access denied: cannot create borrow in site %s from site %s", borrow.MaCN, userSite)
	}

	db, err := r.GetConnection(borrow.MaCN)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", borrow.MaCN, err)
	}

	// Validate fragmentation constraint
	data := map[string]interface{}{
		"MaCN": borrow.MaCN,
	}
	if err := r.ValidateFragmentation(ctx, "PHIEUMUON", data, borrow.MaCN); err != nil {
		return fmt.Errorf("fragmentation validation failed: %w", err)
	}

	// Validate borrow eligibility
	if err := r.CanBorrowBook(ctx, borrow.MaDG, borrow.MaQuyenSach, borrow.MaCN); err != nil {
		return fmt.Errorf("borrow validation failed: %w", err)
	}

	// Execute borrow operation within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		// Double-check book availability (within transaction for consistency)
		var bookStatus string
		err := tx.QueryRowContext(ctx, `
			SELECT TinhTrang 
			FROM QUYENSACH 
			WHERE MaQuyenSach = ? AND MaCN = ?
		`, borrow.MaQuyenSach, borrow.MaCN).Scan(&bookStatus)

		if err != nil {
			return fmt.Errorf("book copy not found: %w", err)
		}

		if bookStatus != "Có sẵn" {
			return fmt.Errorf("book copy %s is not available (status: %s)", borrow.MaQuyenSach, bookStatus)
		}

		// Update book status to borrowed
		_, err = tx.ExecContext(ctx, `
			UPDATE QUYENSACH 
			SET TinhTrang = N'Đang được mượn'
			WHERE MaQuyenSach = ? AND MaCN = ?
		`, borrow.MaQuyenSach, borrow.MaCN)

		if err != nil {
			return fmt.Errorf("failed to update book status: %w", err)
		}

		// Create borrow record
		query := `
			INSERT INTO PHIEUMUON (MaDG, MaQuyenSach, MaCN, NgayMuon)
			VALUES (?, ?, ?, ?)
		`

		result, err := tx.ExecContext(ctx, query,
			borrow.MaDG, borrow.MaQuyenSach, borrow.MaCN, time.Now())
		if err != nil {
			return fmt.Errorf("failed to create borrow record: %w", err)
		}

		// Get the generated borrow ID
		borrowID, err := result.LastInsertId()
		if err != nil {
			return fmt.Errorf("failed to get borrow ID: %w", err)
		}

		log.Printf("Borrow record %d created for reader %s, book %s in site %s",
			borrowID, borrow.MaDG, borrow.MaQuyenSach, borrow.MaCN)
		return nil
	})
}

// ReturnBook processes book return with validation (FR3)
func (r *BorrowRepository) ReturnBook(ctx context.Context, maQuyenSach string, userSite string) error {
	// Find which site the book copy belongs to
	bookCopy, err := r.GetActiveBookCopy(ctx, maQuyenSach)
	if err != nil {
		return fmt.Errorf("failed to locate book copy: %w", err)
	}

	// Authorization: only allow return in user's site
	if bookCopy.MaCN != userSite {
		return fmt.Errorf("access denied: cannot return book in site %s from site %s", bookCopy.MaCN, userSite)
	}

	db, err := r.GetConnection(bookCopy.MaCN)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", bookCopy.MaCN, err)
	}

	// Execute return operation within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		// Find active borrow record
		var borrowID int
		var borrowedDate time.Time
		err := tx.QueryRowContext(ctx, `
			SELECT MaPM, NgayMuon
			FROM PHIEUMUON 
			WHERE MaQuyenSach = ? AND MaCN = ? AND NgayTra IS NULL
		`, maQuyenSach, bookCopy.MaCN).Scan(&borrowID, &borrowedDate)

		if err != nil {
			if err == sql.ErrNoRows {
				return fmt.Errorf("no active borrow record found for book copy %s", maQuyenSach)
			}
			return fmt.Errorf("failed to find borrow record: %w", err)
		}

		// Update borrow record with return date
		_, err = tx.ExecContext(ctx, `
			UPDATE PHIEUMUON 
			SET NgayTra = ?
			WHERE MaPM = ?
		`, time.Now(), borrowID)

		if err != nil {
			return fmt.Errorf("failed to update borrow record: %w", err)
		}

		// Update book status to available
		_, err = tx.ExecContext(ctx, `
			UPDATE QUYENSACH 
			SET TinhTrang = N'Có sẵn'
			WHERE MaQuyenSach = ? AND MaCN = ?
		`, maQuyenSach, bookCopy.MaCN)

		if err != nil {
			return fmt.Errorf("failed to update book status: %w", err)
		}

		log.Printf("Book %s returned successfully, borrow record %d updated in site %s",
			maQuyenSach, borrowID, bookCopy.MaCN)
		return nil
	})
}

// GetBorrowByID retrieves a borrow record by ID
func (r *BorrowRepository) GetBorrowByID(ctx context.Context, maPM int) (*models.PhieuMuon, error) {
	// Try to find borrow record in all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	query := `
		SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON
		WHERE MaPM = ?
	`

	for siteID, db := range connections {
		var borrow models.PhieuMuon
		var ngayTra sql.NullTime

		err := db.QueryRowContext(ctx, query, maPM).Scan(
			&borrow.MaPM, &borrow.MaDG, &borrow.MaQuyenSach,
			&borrow.MaCN, &borrow.NgayMuon, &ngayTra)

		if err == nil {
			if ngayTra.Valid {
				borrow.NgayTra = &ngayTra.Time
			}
			log.Printf("Borrow record %d found in site %s", maPM, siteID)
			return &borrow, nil
		}

		if err != sql.ErrNoRows {
			log.Printf("Error querying borrow record in site %s: %v", siteID, err)
		}
	}

	return nil, fmt.Errorf("borrow record not found: %d", maPM)
}

// GetBorrowsBySite retrieves all borrow records for a specific site
func (r *BorrowRepository) GetBorrowsBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.PhieuMuon, int, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	// Get total count
	countQuery := `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaCN = ?
	`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{siteID})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total borrow count: %w", err)
	}

	// Get paginated data
	baseQuery := `
		SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON
		WHERE MaCN = ?
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery, []interface{}{siteID}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query borrow records: %w", err)
	}
	defer rows.Close()

	var borrows []*models.PhieuMuon
	for rows.Next() {
		borrow, err := r.scanPhieuMuon(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan borrow record: %w", err)
		}
		borrows = append(borrows, borrow)
	}

	return borrows, totalCount, nil
}

// GetActiveBorrowsByReader retrieves active borrows for a specific reader
func (r *BorrowRepository) GetActiveBorrowsByReader(ctx context.Context, maDG string) ([]*models.PhieuMuon, error) {
	// Try to find reader's borrows in all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	var allBorrows []*models.PhieuMuon

	query := `
		SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON
		WHERE MaDG = ? AND NgayTra IS NULL
		ORDER BY NgayMuon DESC
	`

	for siteID, db := range connections {
		rows, err := db.QueryContext(ctx, query, maDG)
		if err != nil {
			log.Printf("Error querying active borrows from site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			borrow, err := r.scanPhieuMuon(rows)
			if err != nil {
				log.Printf("Error scanning borrow from site %s: %v", siteID, err)
				continue
			}
			allBorrows = append(allBorrows, borrow)
		}
	}

	return allBorrows, nil
}

// GetBorrowHistory retrieves borrow history for a reader with pagination
func (r *BorrowRepository) GetBorrowHistory(ctx context.Context, maDG string, pagination *utils.PaginationParams) ([]*models.PhieuMuon, int, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get site connections: %w", err)
	}

	var allBorrows []*models.PhieuMuon
	totalCount := 0

	query := `
		SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON
		WHERE MaDG = ?
		ORDER BY NgayMuon DESC
	`

	for siteID, db := range connections {
		// Get count from this site
		countQuery := `SELECT COUNT(*) FROM PHIEUMUON WHERE MaDG = ?`
		siteCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{maDG})
		if err != nil {
			log.Printf("Error getting borrow count from site %s: %v", siteID, err)
			continue
		}
		totalCount += siteCount

		// Get borrow records from this site
		rows, err := db.QueryContext(ctx, query, maDG)
		if err != nil {
			log.Printf("Error querying borrow history from site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			borrow, err := r.scanPhieuMuon(rows)
			if err != nil {
				log.Printf("Error scanning borrow history from site %s: %v", siteID, err)
				continue
			}
			allBorrows = append(allBorrows, borrow)
		}
	}

	// Apply pagination to combined results
	if pagination != nil {
		offset := pagination.CalculateOffset()
		end := offset + pagination.Size

		if offset >= len(allBorrows) {
			return []*models.PhieuMuon{}, totalCount, nil
		}

		if end > len(allBorrows) {
			end = len(allBorrows)
		}

		allBorrows = allBorrows[offset:end]
	}

	return allBorrows, totalCount, nil
}

// GetOverdueBooks retrieves overdue books for a site
func (r *BorrowRepository) GetOverdueBooks(ctx context.Context, siteID string) ([]*models.BorrowRecordWithDetails, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT 
			pm.MaPM,
			s.ISBN, s.TenSach, s.TacGia,
			dg.MaDG, dg.HoTen,
			CONVERT(varchar, pm.NgayMuon, 23) as BorrowDate,
			CONVERT(varchar, DATEADD(day, 30, pm.NgayMuon), 23) as DueDate,
			'' as ReturnDate,
			'Overdue' as Status,
			DATEDIFF(day, DATEADD(day, 30, pm.NgayMuon), GETDATE()) as DaysOverdue,
			pm.MaQuyenSach,
			pm.MaCN
		FROM PHIEUMUON pm
		JOIN QUYENSACH qs ON pm.MaQuyenSach = qs.MaQuyenSach
		JOIN SACH s ON qs.ISBN = s.ISBN
		JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
		WHERE pm.MaCN = ? 
			AND pm.NgayTra IS NULL 
			AND DATEDIFF(day, pm.NgayMuon, GETDATE()) > 30
		ORDER BY pm.NgayMuon
	`

	rows, err := db.QueryContext(ctx, query, siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to query overdue books: %w", err)
	}
	defer rows.Close()

	var overdueBooks []*models.BorrowRecordWithDetails
	for rows.Next() {
		var record models.BorrowRecordWithDetails
		err := rows.Scan(
			&record.MaPM, &record.BookISBN, &record.BookTitle, &record.BookAuthor,
			&record.ReaderID, &record.ReaderName, &record.BorrowDate, &record.DueDate,
			&record.ReturnDate, &record.Status, &record.DaysOverdue,
			&record.BookCopyID, &record.Branch)
		if err != nil {
			return nil, fmt.Errorf("failed to scan overdue book record: %w", err)
		}
		overdueBooks = append(overdueBooks, &record)
	}

	return overdueBooks, nil
}

// GetBorrowRecordsWithDetails retrieves detailed borrow records for a site
func (r *BorrowRepository) GetBorrowRecordsWithDetails(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.BorrowRecordWithDetails, int, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	// Get total count
	countQuery := `
		SELECT COUNT(*) 
		FROM PHIEUMUON pm
		JOIN QUYENSACH qs ON pm.MaQuyenSach = qs.MaQuyenSach
		JOIN SACH s ON qs.ISBN = s.ISBN
		JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
		WHERE pm.MaCN = ?
	`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{siteID})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total borrow details count: %w", err)
	}

	// Get detailed borrow records
	baseQuery := `
		SELECT 
			pm.MaPM,
			s.ISBN, s.TenSach, s.TacGia,
			dg.MaDG, dg.HoTen,
			CONVERT(varchar, pm.NgayMuon, 23) as BorrowDate,
			CONVERT(varchar, DATEADD(day, 30, pm.NgayMuon), 23) as DueDate,
			ISNULL(CONVERT(varchar, pm.NgayTra, 23), '') as ReturnDate,
			CASE 
				WHEN pm.NgayTra IS NOT NULL THEN 'Returned'
				WHEN DATEDIFF(day, pm.NgayMuon, GETDATE()) > 30 THEN 'Overdue'
				ELSE 'Borrowed'
			END as Status,
			CASE 
				WHEN pm.NgayTra IS NULL AND DATEDIFF(day, pm.NgayMuon, GETDATE()) > 30 
				THEN DATEDIFF(day, DATEADD(day, 30, pm.NgayMuon), GETDATE())
				ELSE 0
			END as DaysOverdue,
			pm.MaQuyenSach,
			pm.MaCN
		FROM PHIEUMUON pm
		JOIN QUYENSACH qs ON pm.MaQuyenSach = qs.MaQuyenSach
		JOIN SACH s ON qs.ISBN = s.ISBN
		JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
		WHERE pm.MaCN = ?
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery, []interface{}{siteID}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query borrow details: %w", err)
	}
	defer rows.Close()

	var records []*models.BorrowRecordWithDetails
	for rows.Next() {
		var record models.BorrowRecordWithDetails
		err := rows.Scan(
			&record.MaPM, &record.BookISBN, &record.BookTitle, &record.BookAuthor,
			&record.ReaderID, &record.ReaderName, &record.BorrowDate, &record.DueDate,
			&record.ReturnDate, &record.Status, &record.DaysOverdue,
			&record.BookCopyID, &record.Branch)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan borrow details: %w", err)
		}
		records = append(records, &record)
	}

	return records, totalCount, nil
}

// CanBorrowBook validates if a reader can borrow a specific book
func (r *BorrowRepository) CanBorrowBook(ctx context.Context, maDG, maQuyenSach, siteID string) error {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	// Check if reader exists and belongs to this site
	var readerCount int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM DOCGIA 
		WHERE MaDG = ? AND MaCN_DangKy = ?
	`, maDG, siteID).Scan(&readerCount)

	if err != nil {
		return fmt.Errorf("failed to validate reader: %w", err)
	}
	if readerCount == 0 {
		return fmt.Errorf("reader %s not found in site %s", maDG, siteID)
	}

	// Check if book copy exists and is available
	var bookStatus string
	err = db.QueryRowContext(ctx, `
		SELECT TinhTrang 
		FROM QUYENSACH 
		WHERE MaQuyenSach = ? AND MaCN = ?
	`, maQuyenSach, siteID).Scan(&bookStatus)

	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("book copy %s not found in site %s", maQuyenSach, siteID)
		}
		return fmt.Errorf("failed to check book availability: %w", err)
	}

	if bookStatus != "Có sẵn" {
		return fmt.Errorf("book copy %s is not available (status: %s)", maQuyenSach, bookStatus)
	}

	// Check if reader has any overdue books
	var overdueCount int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaDG = ? AND NgayTra IS NULL 
			AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
	`, maDG).Scan(&overdueCount)

	if err != nil {
		return fmt.Errorf("failed to check overdue books: %w", err)
	}
	if overdueCount > 0 {
		return fmt.Errorf("reader %s has %d overdue books", maDG, overdueCount)
	}

	// Check borrow limit (e.g., max 3 books)
	var activeBorrows int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaDG = ? AND NgayTra IS NULL
	`, maDG).Scan(&activeBorrows)

	if err != nil {
		return fmt.Errorf("failed to check active borrows: %w", err)
	}
	if activeBorrows >= 3 {
		return fmt.Errorf("reader %s has reached maximum borrow limit (%d books)", maDG, activeBorrows)
	}

	return nil
}

// GetActiveBookCopy retrieves book copy information for active borrow operations
func (r *BorrowRepository) GetActiveBookCopy(ctx context.Context, maQuyenSach string) (*models.QuyenSach, error) {
	// Try to find book copy in all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	query := `
		SELECT MaQuyenSach, ISBN, MaCN, TinhTrang
		FROM QUYENSACH
		WHERE MaQuyenSach = ?
	`

	for siteID, db := range connections {
		var bookCopy models.QuyenSach
		err := db.QueryRowContext(ctx, query, maQuyenSach).Scan(
			&bookCopy.MaQuyenSach, &bookCopy.ISBN, &bookCopy.MaCN, &bookCopy.TinhTrang)

		if err == nil {
			return &bookCopy, nil
		}

		if err != sql.ErrNoRows {
			log.Printf("Error querying book copy in site %s: %v", siteID, err)
		}
	}

	return nil, fmt.Errorf("book copy not found: %s", maQuyenSach)
}

// GetBorrowStatistics retrieves borrowing statistics for a site
func (r *BorrowRepository) GetBorrowStatistics(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	stats := make(map[string]interface{})

	// Total borrows
	var totalBorrows int
	err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM PHIEUMUON WHERE MaCN = ?", siteID).Scan(&totalBorrows)
	if err != nil {
		return nil, fmt.Errorf("failed to get total borrows: %w", err)
	}
	stats["totalBorrows"] = totalBorrows

	// Active borrows
	var activeBorrows int
	err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM PHIEUMUON WHERE MaCN = ? AND NgayTra IS NULL", siteID).Scan(&activeBorrows)
	if err != nil {
		return nil, fmt.Errorf("failed to get active borrows: %w", err)
	}
	stats["activeBorrows"] = activeBorrows

	// Overdue books
	var overdueBooks int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL 
			AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
	`, siteID).Scan(&overdueBooks)
	if err != nil {
		return nil, fmt.Errorf("failed to get overdue books: %w", err)
	}
	stats["overdueBooks"] = overdueBooks

	// Average borrow duration (for returned books)
	var avgDuration sql.NullFloat64
	err = db.QueryRowContext(ctx, `
		SELECT AVG(CAST(DATEDIFF(day, NgayMuon, NgayTra) AS FLOAT))
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NOT NULL
	`, siteID).Scan(&avgDuration)
	if err != nil {
		return nil, fmt.Errorf("failed to get average duration: %w", err)
	}
	if avgDuration.Valid {
		stats["avgBorrowDuration"] = avgDuration.Float64
	} else {
		stats["avgBorrowDuration"] = 0
	}

	return stats, nil
}

// GetPopularBooks retrieves most frequently borrowed books for a site
func (r *BorrowRepository) GetPopularBooks(ctx context.Context, siteID string, limit int) ([]*models.BookWithAvailability, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT TOP (?) 
			s.ISBN, s.TenSach, s.TacGia,
			COUNT(qs.MaQuyenSach) as TotalCount,
			SUM(CASE WHEN qs.TinhTrang = N'Có sẵn' THEN 1 ELSE 0 END) as AvailableCount,
			SUM(CASE WHEN qs.TinhTrang = N'Đang được mượn' THEN 1 ELSE 0 END) as BorrowedCount
		FROM SACH s
		JOIN QUYENSACH qs ON s.ISBN = qs.ISBN AND qs.MaCN = ?
		JOIN PHIEUMUON pm ON qs.MaQuyenSach = pm.MaQuyenSach
		GROUP BY s.ISBN, s.TenSach, s.TacGia
		ORDER BY COUNT(pm.MaPM) DESC
	`

	rows, err := db.QueryContext(ctx, query, limit, siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to query popular books: %w", err)
	}
	defer rows.Close()

	var books []*models.BookWithAvailability
	for rows.Next() {
		var book models.BookWithAvailability
		err := rows.Scan(
			&book.ISBN, &book.TenSach, &book.TacGia,
			&book.TotalCount, &book.AvailableCount, &book.BorrowedCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan popular book: %w", err)
		}
		books = append(books, &book)
	}

	return books, nil
}

// scanPhieuMuon scans a row into PhieuMuon model with null handling
func (r *BorrowRepository) scanPhieuMuon(rows *sql.Rows) (*models.PhieuMuon, error) {
	var borrow models.PhieuMuon
	var ngayTra sql.NullTime

	err := rows.Scan(&borrow.MaPM, &borrow.MaDG, &borrow.MaQuyenSach,
		&borrow.MaCN, &borrow.NgayMuon, &ngayTra)
	if err != nil {
		return nil, fmt.Errorf("failed to scan PhieuMuon: %w", err)
	}

	if ngayTra.Valid {
		borrow.NgayTra = &ngayTra.Time
	}

	return &borrow, nil
}
