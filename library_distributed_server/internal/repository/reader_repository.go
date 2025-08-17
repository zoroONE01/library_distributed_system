package repository

import (
	"context"
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
	"log"
)

// ReaderRepository handles reader operations using raw SQL queries
type ReaderRepository struct {
	*BaseRepository
	siteID string // Current site for this repository instance
}

// ReaderRepositoryInterface defines reader-related operations with raw SQL
type ReaderRepositoryInterface interface {
	// Local operations (site-specific)
	CreateReader(ctx context.Context, reader *models.DocGia, userSite string) error
	GetReaderByID(ctx context.Context, maDG string) (*models.DocGia, error)
	UpdateReader(ctx context.Context, reader *models.DocGia, userSite string) error
	DeleteReader(ctx context.Context, maDG string, userSite string) error
	GetReadersBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.DocGia, int, error)

	// Distributed operations (manager-only)
	GetAllReaders(ctx context.Context, pagination *utils.PaginationParams) ([]*models.DocGia, int, error)
	SearchReaders(ctx context.Context, query string, pagination *utils.PaginationParams) ([]*models.DocGia, int, error)
	GetReaderWithStats(ctx context.Context, maDG string) (*models.ReaderWithStats, error)
	GetReadersWithStats(ctx context.Context, siteID string) ([]*models.ReaderWithStats, error)
}

// NewReaderRepository creates a new reader repository with raw SQL
func NewReaderRepository(config *config.Config, siteID string) ReaderRepositoryInterface {
	return &ReaderRepository{
		BaseRepository: NewBaseRepository(config),
		siteID:         siteID,
	}
}

// CreateReader creates a new reader with fragmentation validation (FR8)
func (r *ReaderRepository) CreateReader(ctx context.Context, reader *models.DocGia, userSite string) error {
	// Authorization: only allow creation in user's site
	if reader.MaCNDangKy != userSite {
		return fmt.Errorf("access denied: cannot create reader in site %s from site %s", reader.MaCNDangKy, userSite)
	}

	db, err := r.GetConnection(reader.MaCNDangKy)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", reader.MaCNDangKy, err)
	}

	// Validate fragmentation constraint
	data := map[string]interface{}{
		"MaCN_DangKy": reader.MaCNDangKy,
	}
	if err := r.ValidateFragmentation(ctx, "DOCGIA", data, reader.MaCNDangKy); err != nil {
		return fmt.Errorf("fragmentation validation failed: %w", err)
	}

	// Check if reader ID already exists
	exists, err := r.CheckRecordExists(ctx, db, "DOCGIA", map[string]interface{}{
		"MaDG": reader.MaDG,
	})
	if err != nil {
		return fmt.Errorf("failed to check reader existence: %w", err)
	}
	if exists {
		return fmt.Errorf("reader with ID %s already exists", reader.MaDG)
	}

	// Validate that the branch exists
	exists, err = r.CheckRecordExists(ctx, db, "CHINHANH", map[string]interface{}{
		"MaCN": reader.MaCNDangKy,
	})
	if err != nil {
		return fmt.Errorf("failed to validate branch: %w", err)
	}
	if !exists {
		return fmt.Errorf("branch %s does not exist", reader.MaCNDangKy)
	}

	// Execute insert within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		query := `
			INSERT INTO DOCGIA (MaDG, HoTen, MaCN_DangKy)
			VALUES (?, ?, ?)
		`

		_, err := tx.ExecContext(ctx, query, reader.MaDG, reader.HoTen, reader.MaCNDangKy)
		if err != nil {
			return fmt.Errorf("failed to insert reader: %w", err)
		}

		log.Printf("Reader %s created in site %s", reader.MaDG, reader.MaCNDangKy)
		return nil
	})
}

// GetReaderByID retrieves a reader by ID from the appropriate site
func (r *ReaderRepository) GetReaderByID(ctx context.Context, maDG string) (*models.DocGia, error) {
	// Try to find reader in all sites since we don't know which site they belong to
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	query := `
		SELECT d.MaDG, d.HoTen, d.MaCN_DangKy
		FROM DOCGIA d
		WHERE d.MaDG = ?
	`

	for siteID, db := range connections {
		var reader models.DocGia
		err := db.QueryRowContext(ctx, query, maDG).Scan(
			&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)

		if err == nil {
			log.Printf("Reader %s found in site %s", maDG, siteID)
			return &reader, nil
		}

		if err != sql.ErrNoRows {
			log.Printf("Error querying reader in site %s: %v", siteID, err)
		}
	}

	return nil, fmt.Errorf("reader not found: %s", maDG)
}

// UpdateReader updates reader information with authorization check
func (r *ReaderRepository) UpdateReader(ctx context.Context, reader *models.DocGia, userSite string) error {
	// First get the existing reader to determine which site they belong to
	existingReader, err := r.GetReaderByID(ctx, reader.MaDG)
	if err != nil {
		return fmt.Errorf("reader not found for update: %w", err)
	}

	// Authorization: only allow update in user's site
	if existingReader.MaCNDangKy != userSite {
		return fmt.Errorf("access denied: cannot update reader in site %s from site %s",
			existingReader.MaCNDangKy, userSite)
	}

	// Get connection to the appropriate site
	db, err := r.GetConnection(existingReader.MaCNDangKy)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", existingReader.MaCNDangKy, err)
	}

	// Execute update within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		query := `
			UPDATE DOCGIA 
			SET HoTen = ?
			WHERE MaDG = ? AND MaCN_DangKy = ?
		`

		result, err := tx.ExecContext(ctx, query, reader.HoTen, reader.MaDG, existingReader.MaCNDangKy)
		if err != nil {
			return fmt.Errorf("failed to update reader: %w", err)
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			return fmt.Errorf("failed to get rows affected: %w", err)
		}

		if rowsAffected == 0 {
			return fmt.Errorf("no reader updated with ID: %s", reader.MaDG)
		}

		log.Printf("Reader %s updated in site %s", reader.MaDG, existingReader.MaCNDangKy)
		return nil
	})
}

// DeleteReader deletes a reader with constraint validation
func (r *ReaderRepository) DeleteReader(ctx context.Context, maDG string, userSite string) error {
	// First get the existing reader to determine which site they belong to
	existingReader, err := r.GetReaderByID(ctx, maDG)
	if err != nil {
		return fmt.Errorf("reader not found for deletion: %w", err)
	}

	// Authorization: only allow deletion in user's site
	if existingReader.MaCNDangKy != userSite {
		return fmt.Errorf("access denied: cannot delete reader in site %s from site %s",
			existingReader.MaCNDangKy, userSite)
	}

	// Get connection to the appropriate site
	db, err := r.GetConnection(existingReader.MaCNDangKy)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", existingReader.MaCNDangKy, err)
	}

	// Execute deletion within transaction with constraint checking
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		// Check if reader has active borrows
		var activeBorrows int
		err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) 
			FROM PHIEUMUON 
			WHERE MaDG = ? AND NgayTra IS NULL
		`, maDG).Scan(&activeBorrows)

		if err != nil {
			return fmt.Errorf("failed to check active borrows: %w", err)
		}

		if activeBorrows > 0 {
			return fmt.Errorf("cannot delete reader %s: has %d active borrows", maDG, activeBorrows)
		}

		// Delete the reader
		query := `
			DELETE FROM DOCGIA 
			WHERE MaDG = ? AND MaCN_DangKy = ?
		`

		result, err := tx.ExecContext(ctx, query, maDG, existingReader.MaCNDangKy)
		if err != nil {
			return fmt.Errorf("failed to delete reader: %w", err)
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			return fmt.Errorf("failed to get rows affected: %w", err)
		}

		if rowsAffected == 0 {
			return fmt.Errorf("no reader deleted with ID: %s", maDG)
		}

		log.Printf("Reader %s deleted from site %s", maDG, existingReader.MaCNDangKy)
		return nil
	})
}

// GetReadersBySite retrieves all readers for a specific site with pagination
func (r *ReaderRepository) GetReadersBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.DocGia, int, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	// Get total count
	countQuery := `
		SELECT COUNT(*) 
		FROM DOCGIA 
		WHERE MaCN_DangKy = ?
	`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{siteID})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total reader count: %w", err)
	}

	// Get paginated data
	baseQuery := `
		SELECT d.MaDG, d.HoTen, d.MaCN_DangKy
		FROM DOCGIA d
		WHERE d.MaCN_DangKy = ?
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery, []interface{}{siteID}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query readers: %w", err)
	}
	defer rows.Close()

	var readers []*models.DocGia
	for rows.Next() {
		reader, err := r.ScanDocGia(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan reader: %w", err)
		}
		readers = append(readers, reader)
	}

	return readers, totalCount, nil
}

// GetAllReaders retrieves readers from all sites (Manager only)
func (r *ReaderRepository) GetAllReaders(ctx context.Context, pagination *utils.PaginationParams) ([]*models.DocGia, int, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get site connections: %w", err)
	}

	var allReaders []*models.DocGia
	totalCount := 0

	for siteID, db := range connections {
		// Get count from this site
		countQuery := `SELECT COUNT(*) FROM DOCGIA WHERE MaCN_DangKy = ?`
		siteCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{siteID})
		if err != nil {
			log.Printf("Error getting count from site %s: %v", siteID, err)
			continue
		}
		totalCount += siteCount

		// Get readers from this site
		query := `
			SELECT d.MaDG, d.HoTen, d.MaCN_DangKy
			FROM DOCGIA d
			WHERE d.MaCN_DangKy = ?
			ORDER BY d.MaDG
		`

		rows, err := db.QueryContext(ctx, query, siteID)
		if err != nil {
			log.Printf("Error querying readers from site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			reader, err := r.ScanDocGia(rows)
			if err != nil {
				log.Printf("Error scanning reader from site %s: %v", siteID, err)
				continue
			}
			allReaders = append(allReaders, reader)
		}
	}

	// Apply pagination to combined results
	if pagination != nil {
		offset := pagination.CalculateOffset()
		end := offset + pagination.Size

		if offset >= len(allReaders) {
			return []*models.DocGia{}, totalCount, nil
		}

		if end > len(allReaders) {
			end = len(allReaders)
		}

		allReaders = allReaders[offset:end]
	}

	return allReaders, totalCount, nil
}

// SearchReaders searches for readers across all sites by name
func (r *ReaderRepository) SearchReaders(ctx context.Context, query string, pagination *utils.PaginationParams) ([]*models.DocGia, int, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get site connections: %w", err)
	}

	var allReaders []*models.DocGia
	totalCount := 0

	searchQuery := `
		SELECT d.MaDG, d.HoTen, d.MaCN_DangKy
		FROM DOCGIA d
		WHERE d.MaCN_DangKy = ? AND (
			d.MaDG LIKE ? OR 
			d.HoTen LIKE ?
		)
		ORDER BY d.HoTen
	`

	searchPattern := "%" + query + "%"

	for siteID, db := range connections {
		// Get count from this site
		countQuery := `
			SELECT COUNT(*) 
			FROM DOCGIA 
			WHERE MaCN_DangKy = ? AND (MaDG LIKE ? OR HoTen LIKE ?)
		`
		siteCount, err := r.GetTotalCount(ctx, db, countQuery,
			[]interface{}{siteID, searchPattern, searchPattern})
		if err != nil {
			log.Printf("Error getting search count from site %s: %v", siteID, err)
			continue
		}
		totalCount += siteCount

		// Get search results from this site
		rows, err := db.QueryContext(ctx, searchQuery, siteID, searchPattern, searchPattern)
		if err != nil {
			log.Printf("Error searching readers in site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			reader, err := r.ScanDocGia(rows)
			if err != nil {
				log.Printf("Error scanning search result from site %s: %v", siteID, err)
				continue
			}
			allReaders = append(allReaders, reader)
		}
	}

	// Apply pagination to combined results
	if pagination != nil {
		offset := pagination.CalculateOffset()
		end := offset + pagination.Size

		if offset >= len(allReaders) {
			return []*models.DocGia{}, totalCount, nil
		}

		if end > len(allReaders) {
			end = len(allReaders)
		}

		allReaders = allReaders[offset:end]
	}

	return allReaders, totalCount, nil
}

// GetReaderWithStats retrieves reader with borrowing statistics
func (r *ReaderRepository) GetReaderWithStats(ctx context.Context, maDG string) (*models.ReaderWithStats, error) {
	// First get the basic reader info
	reader, err := r.GetReaderByID(ctx, maDG)
	if err != nil {
		return nil, fmt.Errorf("reader not found: %w", err)
	}

	// Get connection to the reader's site
	db, err := r.GetConnection(reader.MaCNDangKy)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", reader.MaCNDangKy, err)
	}

	// Query borrowing statistics
	statsQuery := `
		SELECT 
			COUNT(*) as TotalBorrowed,
			SUM(CASE WHEN NgayTra IS NULL THEN 1 ELSE 0 END) as CurrentBorrowed,
			SUM(CASE WHEN NgayTra IS NULL AND DATEDIFF(day, NgayMuon, GETDATE()) > 30 THEN 1 ELSE 0 END) as OverdueBooks,
			MAX(NgayMuon) as LastBorrowDate
		FROM PHIEUMUON 
		WHERE MaDG = ? AND MaCN = ?
	`

	var stats models.ReaderWithStats
	var lastBorrowDate sql.NullTime

	err = db.QueryRowContext(ctx, statsQuery, maDG, reader.MaCNDangKy).Scan(
		&stats.TotalBorrowed,
		&stats.CurrentBorrowed,
		&stats.OverdueBooks,
		&lastBorrowDate,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get reader statistics: %w", err)
	}

	// Populate reader info
	stats.MaDG = reader.MaDG
	stats.HoTen = reader.HoTen
	stats.MaCNDangKy = reader.MaCNDangKy

	if lastBorrowDate.Valid {
		stats.LastBorrowDate = lastBorrowDate.Time.Format("2006-01-02")
	} else {
		stats.LastBorrowDate = ""
	}

	return &stats, nil
}

// GetReadersWithStats retrieves all readers with statistics for a site
func (r *ReaderRepository) GetReadersWithStats(ctx context.Context, siteID string) ([]*models.ReaderWithStats, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT 
			d.MaDG,
			d.HoTen,
			d.MaCN_DangKy,
			ISNULL(stats.TotalBorrowed, 0) as TotalBorrowed,
			ISNULL(stats.CurrentBorrowed, 0) as CurrentBorrowed,
			ISNULL(stats.OverdueBooks, 0) as OverdueBooks,
			ISNULL(CONVERT(varchar, stats.LastBorrowDate, 23), '') as LastBorrowDate
		FROM DOCGIA d
		LEFT JOIN (
			SELECT 
				MaDG,
				COUNT(*) as TotalBorrowed,
				SUM(CASE WHEN NgayTra IS NULL THEN 1 ELSE 0 END) as CurrentBorrowed,
				SUM(CASE WHEN NgayTra IS NULL AND DATEDIFF(day, NgayMuon, GETDATE()) > 30 THEN 1 ELSE 0 END) as OverdueBooks,
				MAX(NgayMuon) as LastBorrowDate
			FROM PHIEUMUON 
			WHERE MaCN = ?
			GROUP BY MaDG
		) stats ON d.MaDG = stats.MaDG
		WHERE d.MaCN_DangKy = ?
		ORDER BY d.HoTen
	`

	rows, err := db.QueryContext(ctx, query, siteID, siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to query readers with stats: %w", err)
	}
	defer rows.Close()

	var readers []*models.ReaderWithStats
	for rows.Next() {
		var reader models.ReaderWithStats
		err := rows.Scan(
			&reader.MaDG,
			&reader.HoTen,
			&reader.MaCNDangKy,
			&reader.TotalBorrowed,
			&reader.CurrentBorrowed,
			&reader.OverdueBooks,
			&reader.LastBorrowDate,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan reader with stats: %w", err)
		}
		readers = append(readers, &reader)
	}

	return readers, nil
}
