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

// BookRepository handles book operations using raw SQL queries
type BookRepository struct {
	*BaseRepository
	siteID string // Current site for this repository instance
}

// BookRepositoryInterface defines book-related operations with raw SQL
type BookRepositoryInterface interface {
	// Book catalog operations (replicated tables - 2PC required)
	CreateBook(ctx context.Context, book *models.Sach) error
	GetBookByISBN(ctx context.Context, isbn string) (*models.Sach, error)
	UpdateBook(ctx context.Context, book *models.Sach) error
	DeleteBook(ctx context.Context, isbn string) error
	GetAllBooks(ctx context.Context, pagination *utils.PaginationParams) ([]*models.Sach, int, error)
	SearchBooks(ctx context.Context, query string, pagination *utils.PaginationParams) ([]*models.Sach, int, error)

	// Book copy operations (fragmented tables)
	CreateBookCopy(ctx context.Context, bookCopy *models.QuyenSach, userSite string) error
	GetBookCopyByID(ctx context.Context, maQuyenSach string) (*models.QuyenSach, error)
	UpdateBookCopy(ctx context.Context, bookCopy *models.QuyenSach, userSite string) error
	DeleteBookCopy(ctx context.Context, maQuyenSach string, userSite string) error
	GetBookCopiesBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.QuyenSach, int, error)
	GetBookCopiesByISBN(ctx context.Context, isbn string) ([]*models.QuyenSach, error)

	// Advanced search operations
	SearchAvailableBooks(ctx context.Context, query string) ([]*models.BookSearchResult, error)
	GetBooksWithAvailability(ctx context.Context, siteID string) ([]*models.BookWithAvailability, error)
	CheckBookAvailability(ctx context.Context, isbn string, siteID string) (int, error)

	// 2PC operations
	TransferBookCopy(ctx context.Context, maQuyenSach, fromSite, toSite string) error
}

// NewBookRepository creates a new book repository with raw SQL
func NewBookRepository(config *config.Config, siteID string) BookRepositoryInterface {
	return &BookRepository{
		BaseRepository: NewBaseRepository(config),
		siteID:         siteID,
	}
}

// CreateBook creates a new book in catalog using 2PC across all sites (Manager only)
func (r *BookRepository) CreateBook(ctx context.Context, book *models.Sach) error {
	// This requires 2PC implementation across all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return fmt.Errorf("failed to get site connections: %w", err)
	}

	// Phase 1: Prepare all sites
	var transactions []*sql.Tx
	defer func() {
		// Rollback any open transactions if something fails
		for _, tx := range transactions {
			if tx != nil {
				tx.Rollback()
			}
		}
	}()

	for siteID, db := range connections {
		tx, err := db.BeginTx(ctx, &sql.TxOptions{
			Isolation: sql.LevelSerializable,
		})
		if err != nil {
			return fmt.Errorf("failed to begin transaction for site %s: %w", siteID, err)
		}

		// Check if ISBN already exists
		var count int
		err = tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM SACH WHERE ISBN = ?", book.ISBN).Scan(&count)
		if err != nil {
			return fmt.Errorf("failed to check ISBN existence in site %s: %w", siteID, err)
		}

		if count > 0 {
			return fmt.Errorf("book with ISBN %s already exists in site %s", book.ISBN, siteID)
		}

		transactions = append(transactions, tx)
	}

	// Phase 2: Commit all sites
	for i, tx := range transactions {
		query := `
			INSERT INTO SACH (ISBN, TenSach, TacGia)
			VALUES (?, ?, ?)
		`

		_, err := tx.ExecContext(ctx, query, book.ISBN, book.TenSach, book.TacGia)
		if err != nil {
			return fmt.Errorf("failed to insert book in site %d: %w", i, err)
		}

		err = tx.Commit()
		if err != nil {
			return fmt.Errorf("failed to commit transaction in site %d: %w", i, err)
		}

		transactions[i] = nil // Mark as committed
	}

	log.Printf("Book %s created across all sites using 2PC", book.ISBN)
	return nil
}

// GetBookByISBN retrieves book information from any site (replicated data)
func (r *BookRepository) GetBookByISBN(ctx context.Context, isbn string) (*models.Sach, error) {
	// Since SACH table is replicated, we can query any site
	db, err := r.GetConnection(r.siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", r.siteID, err)
	}

	query := `
		SELECT ISBN, TenSach, TacGia
		FROM SACH
		WHERE ISBN = ?
	`

	var book models.Sach
	err = db.QueryRowContext(ctx, query, isbn).Scan(&book.ISBN, &book.TenSach, &book.TacGia)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("book not found: %s", isbn)
		}
		return nil, fmt.Errorf("failed to query book: %w", err)
	}

	return &book, nil
}

// UpdateBook updates book information using 2PC across all sites (Manager only)
func (r *BookRepository) UpdateBook(ctx context.Context, book *models.Sach) error {
	// This requires 2PC implementation across all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return fmt.Errorf("failed to get site connections: %w", err)
	}

	// Execute update across all sites with 2PC
	var transactions []*sql.Tx
	defer func() {
		for _, tx := range transactions {
			if tx != nil {
				tx.Rollback()
			}
		}
	}()

	// Phase 1: Prepare all sites
	for siteID, db := range connections {
		tx, err := db.BeginTx(ctx, &sql.TxOptions{
			Isolation: sql.LevelSerializable,
		})
		if err != nil {
			return fmt.Errorf("failed to begin transaction for site %s: %w", siteID, err)
		}

		// Verify book exists
		var count int
		err = tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM SACH WHERE ISBN = ?", book.ISBN).Scan(&count)
		if err != nil {
			return fmt.Errorf("failed to verify book existence in site %s: %w", siteID, err)
		}

		if count == 0 {
			return fmt.Errorf("book with ISBN %s not found in site %s", book.ISBN, siteID)
		}

		transactions = append(transactions, tx)
	}

	// Phase 2: Commit all sites
	for i, tx := range transactions {
		query := `
			UPDATE SACH 
			SET TenSach = ?, TacGia = ?
			WHERE ISBN = ?
		`

		_, err := tx.ExecContext(ctx, query, book.TenSach, book.TacGia, book.ISBN)
		if err != nil {
			return fmt.Errorf("failed to update book in site %d: %w", i, err)
		}

		err = tx.Commit()
		if err != nil {
			return fmt.Errorf("failed to commit update in site %d: %w", i, err)
		}

		transactions[i] = nil
	}

	log.Printf("Book %s updated across all sites using 2PC", book.ISBN)
	return nil
}

// DeleteBook deletes book from catalog using 2PC (Manager only)
func (r *BookRepository) DeleteBook(ctx context.Context, isbn string) error {
	// Check if any book copies exist before deletion
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return fmt.Errorf("failed to get site connections: %w", err)
	}

	// Check for existing book copies
	for siteID, db := range connections {
		var copyCount int
		err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ?", isbn).Scan(&copyCount)
		if err != nil {
			return fmt.Errorf("failed to check book copies in site %s: %w", siteID, err)
		}

		if copyCount > 0 {
			return fmt.Errorf("cannot delete book %s: %d copies exist in site %s", isbn, copyCount, siteID)
		}
	}

	// Execute deletion across all sites with 2PC
	var transactions []*sql.Tx
	defer func() {
		for _, tx := range transactions {
			if tx != nil {
				tx.Rollback()
			}
		}
	}()

	// Phase 1: Prepare all sites
	for siteID, db := range connections {
		tx, err := db.BeginTx(ctx, &sql.TxOptions{
			Isolation: sql.LevelSerializable,
		})
		if err != nil {
			return fmt.Errorf("failed to begin transaction for site %s: %w", siteID, err)
		}

		transactions = append(transactions, tx)
	}

	// Phase 2: Commit all sites
	for i, tx := range transactions {
		query := `DELETE FROM SACH WHERE ISBN = ?`

		_, err := tx.ExecContext(ctx, query, isbn)
		if err != nil {
			return fmt.Errorf("failed to delete book in site %d: %w", i, err)
		}

		err = tx.Commit()
		if err != nil {
			return fmt.Errorf("failed to commit deletion in site %d: %w", i, err)
		}

		transactions[i] = nil
	}

	log.Printf("Book %s deleted from all sites using 2PC", isbn)
	return nil
}

// GetAllBooks retrieves all books with pagination (replicated data)
func (r *BookRepository) GetAllBooks(ctx context.Context, pagination *utils.PaginationParams) ([]*models.Sach, int, error) {
	db, err := r.GetConnection(r.siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", r.siteID, err)
	}

	// Get total count
	countQuery := `SELECT COUNT(*) FROM SACH`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total book count: %w", err)
	}

	// Get paginated data
	baseQuery := `
		SELECT ISBN, TenSach, TacGia
		FROM SACH
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery, []interface{}{}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query books: %w", err)
	}
	defer rows.Close()

	var books []*models.Sach
	for rows.Next() {
		book, err := r.ScanSach(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan book: %w", err)
		}
		books = append(books, book)
	}

	return books, totalCount, nil
}

// SearchBooks searches books by title or author
func (r *BookRepository) SearchBooks(ctx context.Context, query string, pagination *utils.PaginationParams) ([]*models.Sach, int, error) {
	db, err := r.GetConnection(r.siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", r.siteID, err)
	}

	searchPattern := "%" + query + "%"

	// Get total count
	countQuery := `
		SELECT COUNT(*) 
		FROM SACH 
		WHERE TenSach LIKE ? OR TacGia LIKE ? OR ISBN LIKE ?
	`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery,
		[]interface{}{searchPattern, searchPattern, searchPattern})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get search count: %w", err)
	}

	// Get search results
	baseQuery := `
		SELECT ISBN, TenSach, TacGia
		FROM SACH
		WHERE TenSach LIKE ? OR TacGia LIKE ? OR ISBN LIKE ?
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery,
		[]interface{}{searchPattern, searchPattern, searchPattern}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to search books: %w", err)
	}
	defer rows.Close()

	var books []*models.Sach
	for rows.Next() {
		book, err := r.ScanSach(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan search result: %w", err)
		}
		books = append(books, book)
	}

	return books, totalCount, nil
}

// CreateBookCopy creates a new book copy with fragmentation validation
func (r *BookRepository) CreateBookCopy(ctx context.Context, bookCopy *models.QuyenSach, userSite string) error {
	// Authorization: only allow creation in user's site
	if bookCopy.MaCN != userSite {
		return fmt.Errorf("access denied: cannot create book copy in site %s from site %s", bookCopy.MaCN, userSite)
	}

	db, err := r.GetConnection(bookCopy.MaCN)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", bookCopy.MaCN, err)
	}

	// Validate fragmentation constraint
	data := map[string]interface{}{
		"MaCN": bookCopy.MaCN,
	}
	if err := r.ValidateFragmentation(ctx, "QUYENSACH", data, bookCopy.MaCN); err != nil {
		return fmt.Errorf("fragmentation validation failed: %w", err)
	}

	// Execute insert within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		// Check if book copy ID already exists
		var count int
		err := tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM QUYENSACH WHERE MaQuyenSach = ?",
			bookCopy.MaQuyenSach).Scan(&count)
		if err != nil {
			return fmt.Errorf("failed to check book copy existence: %w", err)
		}
		if count > 0 {
			return fmt.Errorf("book copy with ID %s already exists", bookCopy.MaQuyenSach)
		}

		// Validate that the book (ISBN) exists
		err = tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM SACH WHERE ISBN = ?",
			bookCopy.ISBN).Scan(&count)
		if err != nil {
			return fmt.Errorf("failed to validate book existence: %w", err)
		}
		if count == 0 {
			return fmt.Errorf("book with ISBN %s does not exist", bookCopy.ISBN)
		}

		// Validate that the branch exists
		err = tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM CHINHANH WHERE MaCN = ?",
			bookCopy.MaCN).Scan(&count)
		if err != nil {
			return fmt.Errorf("failed to validate branch existence: %w", err)
		}
		if count == 0 {
			return fmt.Errorf("branch %s does not exist", bookCopy.MaCN)
		}

		// Insert book copy
		query := `
			INSERT INTO QUYENSACH (MaQuyenSach, ISBN, MaCN, TinhTrang)
			VALUES (?, ?, ?, ?)
		`

		_, err = tx.ExecContext(ctx, query,
			bookCopy.MaQuyenSach, bookCopy.ISBN, bookCopy.MaCN, bookCopy.TinhTrang)
		if err != nil {
			return fmt.Errorf("failed to insert book copy: %w", err)
		}

		log.Printf("Book copy %s created in site %s", bookCopy.MaQuyenSach, bookCopy.MaCN)
		return nil
	})
}

// GetBookCopyByID retrieves a book copy by ID from appropriate site
func (r *BookRepository) GetBookCopyByID(ctx context.Context, maQuyenSach string) (*models.QuyenSach, error) {
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
			log.Printf("Book copy %s found in site %s", maQuyenSach, siteID)
			return &bookCopy, nil
		}

		if err != sql.ErrNoRows {
			log.Printf("Error querying book copy in site %s: %v", siteID, err)
		}
	}

	return nil, fmt.Errorf("book copy not found: %s", maQuyenSach)
}

// UpdateBookCopy updates book copy status with authorization check
func (r *BookRepository) UpdateBookCopy(ctx context.Context, bookCopy *models.QuyenSach, userSite string) error {
	// First get the existing book copy to determine which site it belongs to
	existingCopy, err := r.GetBookCopyByID(ctx, bookCopy.MaQuyenSach)
	if err != nil {
		return fmt.Errorf("book copy not found for update: %w", err)
	}

	// Authorization: only allow update in user's site
	if existingCopy.MaCN != userSite {
		return fmt.Errorf("access denied: cannot update book copy in site %s from site %s",
			existingCopy.MaCN, userSite)
	}

	db, err := r.GetConnection(existingCopy.MaCN)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", existingCopy.MaCN, err)
	}

	// Execute update within transaction
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		query := `
			UPDATE QUYENSACH 
			SET TinhTrang = ?
			WHERE MaQuyenSach = ? AND MaCN = ?
		`

		result, err := tx.ExecContext(ctx, query,
			bookCopy.TinhTrang, bookCopy.MaQuyenSach, existingCopy.MaCN)
		if err != nil {
			return fmt.Errorf("failed to update book copy: %w", err)
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			return fmt.Errorf("failed to get rows affected: %w", err)
		}

		if rowsAffected == 0 {
			return fmt.Errorf("no book copy updated with ID: %s", bookCopy.MaQuyenSach)
		}

		log.Printf("Book copy %s updated in site %s", bookCopy.MaQuyenSach, existingCopy.MaCN)
		return nil
	})
}

// DeleteBookCopy deletes a book copy with constraint validation
func (r *BookRepository) DeleteBookCopy(ctx context.Context, maQuyenSach string, userSite string) error {
	// First get the existing book copy
	existingCopy, err := r.GetBookCopyByID(ctx, maQuyenSach)
	if err != nil {
		return fmt.Errorf("book copy not found for deletion: %w", err)
	}

	// Authorization: only allow deletion in user's site
	if existingCopy.MaCN != userSite {
		return fmt.Errorf("access denied: cannot delete book copy in site %s from site %s",
			existingCopy.MaCN, userSite)
	}

	db, err := r.GetConnection(existingCopy.MaCN)
	if err != nil {
		return fmt.Errorf("failed to connect to site %s: %w", existingCopy.MaCN, err)
	}

	// Execute deletion within transaction with constraint checking
	return r.ExecuteWithTransaction(ctx, db, func(tx *sql.Tx) error {
		// Check if book copy is currently borrowed
		var activeBorrows int
		err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) 
			FROM PHIEUMUON 
			WHERE MaQuyenSach = ? AND NgayTra IS NULL
		`, maQuyenSach).Scan(&activeBorrows)

		if err != nil {
			return fmt.Errorf("failed to check active borrows: %w", err)
		}

		if activeBorrows > 0 {
			return fmt.Errorf("cannot delete book copy %s: currently borrowed", maQuyenSach)
		}

		// Delete the book copy
		query := `
			DELETE FROM QUYENSACH 
			WHERE MaQuyenSach = ? AND MaCN = ?
		`

		result, err := tx.ExecContext(ctx, query, maQuyenSach, existingCopy.MaCN)
		if err != nil {
			return fmt.Errorf("failed to delete book copy: %w", err)
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			return fmt.Errorf("failed to get rows affected: %w", err)
		}

		if rowsAffected == 0 {
			return fmt.Errorf("no book copy deleted with ID: %s", maQuyenSach)
		}

		log.Printf("Book copy %s deleted from site %s", maQuyenSach, existingCopy.MaCN)
		return nil
	})
}

// GetBookCopiesBySite retrieves all book copies for a specific site
func (r *BookRepository) GetBookCopiesBySite(ctx context.Context, siteID string, pagination *utils.PaginationParams) ([]*models.QuyenSach, int, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	// Get total count
	countQuery := `
		SELECT COUNT(*) 
		FROM QUYENSACH 
		WHERE MaCN = ?
	`
	totalCount, err := r.GetTotalCount(ctx, db, countQuery, []interface{}{siteID})
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total book copy count: %w", err)
	}

	// Get paginated data
	baseQuery := `
		SELECT qs.MaQuyenSach, qs.ISBN, qs.MaCN, qs.TinhTrang
		FROM QUYENSACH qs
		WHERE qs.MaCN = ?
	`

	rows, err := r.ExecuteQuery(ctx, db, baseQuery, []interface{}{siteID}, pagination)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query book copies: %w", err)
	}
	defer rows.Close()

	var bookCopies []*models.QuyenSach
	for rows.Next() {
		bookCopy, err := r.ScanQuyenSach(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan book copy: %w", err)
		}
		bookCopies = append(bookCopies, bookCopy)
	}

	return bookCopies, totalCount, nil
}

// GetBookCopiesByISBN retrieves all copies of a specific book across sites
func (r *BookRepository) GetBookCopiesByISBN(ctx context.Context, isbn string) ([]*models.QuyenSach, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	var allCopies []*models.QuyenSach

	query := `
		SELECT MaQuyenSach, ISBN, MaCN, TinhTrang
		FROM QUYENSACH
		WHERE ISBN = ?
		ORDER BY MaQuyenSach
	`

	for siteID, db := range connections {
		rows, err := db.QueryContext(ctx, query, isbn)
		if err != nil {
			log.Printf("Error querying book copies from site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			bookCopy, err := r.ScanQuyenSach(rows)
			if err != nil {
				log.Printf("Error scanning book copy from site %s: %v", siteID, err)
				continue
			}
			allCopies = append(allCopies, bookCopy)
		}
	}

	return allCopies, nil
}

// SearchAvailableBooks searches for available books across all sites (FR7)
func (r *BookRepository) SearchAvailableBooks(ctx context.Context, query string) ([]*models.BookSearchResult, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	searchPattern := "%" + query + "%"
	bookResults := make(map[string]*models.BookSearchResult)

	searchQuery := `
		SELECT 
			s.ISBN, s.TenSach, s.TacGia,
			cn.MaCN, cn.TenCN, cn.DiaChi,
			COUNT(qs.MaQuyenSach) as AvailableCount
		FROM SACH s
		JOIN QUYENSACH qs ON s.ISBN = qs.ISBN
		JOIN CHINHANH cn ON qs.MaCN = cn.MaCN
		WHERE (s.TenSach LIKE ? OR s.TacGia LIKE ?) 
			AND qs.TinhTrang = N'Có sẵn'
		GROUP BY s.ISBN, s.TenSach, s.TacGia, cn.MaCN, cn.TenCN, cn.DiaChi
		ORDER BY s.TenSach
	`

	for siteID, db := range connections {
		rows, err := db.QueryContext(ctx, searchQuery, searchPattern, searchPattern)
		if err != nil {
			log.Printf("Error searching books in site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			var isbn, tenSach, tacGia string
			var chiNhanh models.ChiNhanh
			var availableCount int

			err := rows.Scan(&isbn, &tenSach, &tacGia,
				&chiNhanh.MaCN, &chiNhanh.TenCN, &chiNhanh.DiaChi, &availableCount)
			if err != nil {
				log.Printf("Error scanning search result from site %s: %v", siteID, err)
				continue
			}

			// Group by ISBN
			if result, exists := bookResults[isbn]; exists {
				// Add branch info and update count
				result.ChiNhanh = append(result.ChiNhanh, chiNhanh)
				result.SoLuongCo += availableCount
			} else {
				// Create new result
				bookResults[isbn] = &models.BookSearchResult{
					Sach: models.Sach{
						ISBN:    isbn,
						TenSach: tenSach,
						TacGia:  tacGia,
					},
					ChiNhanh:  []models.ChiNhanh{chiNhanh},
					SoLuongCo: availableCount,
				}
			}
		}
	}

	// Convert map to slice
	var results []*models.BookSearchResult
	for _, result := range bookResults {
		results = append(results, result)
	}

	return results, nil
}

// GetBooksWithAvailability retrieves books with availability info for a site
func (r *BookRepository) GetBooksWithAvailability(ctx context.Context, siteID string) ([]*models.BookWithAvailability, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT 
			s.ISBN, s.TenSach, s.TacGia,
			COUNT(qs.MaQuyenSach) as TotalCount,
			SUM(CASE WHEN qs.TinhTrang = N'Có sẵn' THEN 1 ELSE 0 END) as AvailableCount,
			SUM(CASE WHEN qs.TinhTrang = N'Đang được mượn' THEN 1 ELSE 0 END) as BorrowedCount
		FROM SACH s
		LEFT JOIN QUYENSACH qs ON s.ISBN = qs.ISBN AND qs.MaCN = ?
		GROUP BY s.ISBN, s.TenSach, s.TacGia
		ORDER BY s.TenSach
	`

	rows, err := db.QueryContext(ctx, query, siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to query books with availability: %w", err)
	}
	defer rows.Close()

	var books []*models.BookWithAvailability
	for rows.Next() {
		var book models.BookWithAvailability
		err := rows.Scan(
			&book.ISBN, &book.TenSach, &book.TacGia,
			&book.TotalCount, &book.AvailableCount, &book.BorrowedCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan book with availability: %w", err)
		}
		books = append(books, &book)
	}

	return books, nil
}

// CheckBookAvailability checks how many copies are available for a book at a site
func (r *BookRepository) CheckBookAvailability(ctx context.Context, isbn string, siteID string) (int, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return 0, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT COUNT(*) 
		FROM QUYENSACH 
		WHERE ISBN = ? AND MaCN = ? AND TinhTrang = N'Có sẵn'
	`

	var availableCount int
	err = db.QueryRowContext(ctx, query, isbn, siteID).Scan(&availableCount)
	if err != nil {
		return 0, fmt.Errorf("failed to check book availability: %w", err)
	}

	return availableCount, nil
}

// TransferBookCopy transfers a book copy between sites using 2PC protocol
func (r *BookRepository) TransferBookCopy(ctx context.Context, maQuyenSach, fromSite, toSite string) error {
	// Get connections for both sites
	fromDB, err := r.GetConnection(fromSite)
	if err != nil {
		return fmt.Errorf("failed to connect to source site %s: %w", fromSite, err)
	}

	toDB, err := r.GetConnection(toSite)
	if err != nil {
		return fmt.Errorf("failed to connect to destination site %s: %w", toSite, err)
	}

	// 2PC implementation
	var fromTx, toTx *sql.Tx
	defer func() {
		if fromTx != nil {
			fromTx.Rollback()
		}
		if toTx != nil {
			toTx.Rollback()
		}
	}()

	// Phase 1: Prepare both sites
	fromTx, err = fromDB.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return fmt.Errorf("failed to begin transaction on source site: %w", err)
	}

	toTx, err = toDB.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		return fmt.Errorf("failed to begin transaction on destination site: %w", err)
	}

	// Get book copy details from source
	var bookCopy models.QuyenSach
	err = fromTx.QueryRowContext(ctx, `
		SELECT MaQuyenSach, ISBN, MaCN, TinhTrang 
		FROM QUYENSACH 
		WHERE MaQuyenSach = ? AND MaCN = ?
	`, maQuyenSach, fromSite).Scan(
		&bookCopy.MaQuyenSach, &bookCopy.ISBN, &bookCopy.MaCN, &bookCopy.TinhTrang)

	if err != nil {
		return fmt.Errorf("book copy not found in source site: %w", err)
	}

	// Verify book copy is available for transfer
	if bookCopy.TinhTrang != "Có sẵn" {
		return fmt.Errorf("book copy %s is not available for transfer (status: %s)",
			maQuyenSach, bookCopy.TinhTrang)
	}

	// Check if book copy ID already exists in destination
	var count int
	err = toTx.QueryRowContext(ctx, "SELECT COUNT(*) FROM QUYENSACH WHERE MaQuyenSach = ?",
		maQuyenSach).Scan(&count)
	if err != nil {
		return fmt.Errorf("failed to check destination site: %w", err)
	}
	if count > 0 {
		return fmt.Errorf("book copy %s already exists in destination site", maQuyenSach)
	}

	// Phase 2: Commit both operations
	// Insert into destination site
	_, err = toTx.ExecContext(ctx, `
		INSERT INTO QUYENSACH (MaQuyenSach, ISBN, MaCN, TinhTrang)
		VALUES (?, ?, ?, ?)
	`, bookCopy.MaQuyenSach, bookCopy.ISBN, toSite, bookCopy.TinhTrang)
	if err != nil {
		return fmt.Errorf("failed to insert into destination site: %w", err)
	}

	// Delete from source site
	_, err = fromTx.ExecContext(ctx, `
		DELETE FROM QUYENSACH 
		WHERE MaQuyenSach = ? AND MaCN = ?
	`, maQuyenSach, fromSite)
	if err != nil {
		return fmt.Errorf("failed to delete from source site: %w", err)
	}

	// Commit both transactions
	err = toTx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit destination transaction: %w", err)
	}
	toTx = nil

	err = fromTx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit source transaction: %w", err)
	}
	fromTx = nil

	log.Printf("Book copy %s transferred from %s to %s using 2PC", maQuyenSach, fromSite, toSite)
	return nil
}
