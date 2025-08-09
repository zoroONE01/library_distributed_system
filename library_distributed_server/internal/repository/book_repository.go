package repository

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
)

type BookRepository struct {
	*BaseRepository
}

func NewBookRepository(config *config.Config) *BookRepository {
	return &BookRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// GetBooksPaginated gets books with pagination support
func (r *BookRepository) GetBooksPaginated(siteID string, pagination utils.PaginationParams) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Get total count
	countQuery := "SELECT COUNT(*) FROM SACH"
	totalCount, err := r.GetTotalCount(conn, countQuery)
	if err != nil {
		return nil, err
	}

	// Get paginated data
	baseQuery := "SELECT ISBN, TenSach, TacGia FROM SACH"
	paginatedQuery := r.BuildPaginatedQuery(baseQuery, pagination)

	rows, err := conn.Query(paginatedQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var books []models.Sach
	for rows.Next() {
		var book models.Sach
		err := rows.Scan(&book.ISBN, &book.TenSach, &book.TacGia)
		if err != nil {
			return nil, err
		}
		books = append(books, book)
	}

	return &PaginatedResult{
		Data:       books,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetBooksWithAvailabilityPaginated gets books with availability count and pagination
func (r *BookRepository) GetBooksWithAvailabilityPaginated(siteID string, userRole string, pagination utils.PaginationParams) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Get total count of books
	countQuery := "SELECT COUNT(*) FROM SACH"
	totalCount, err := r.GetTotalCount(conn, countQuery)
	if err != nil {
		return nil, err
	}

	// Get paginated book titles
	baseQuery := "SELECT ISBN, TenSach, TacGia FROM SACH"
	paginatedQuery := r.BuildPaginatedQuery(baseQuery, pagination)

	rows, err := conn.Query(paginatedQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sitesToQuery []string
	if userRole == "QUANLY" {
		sitesToQuery = []string{"Q1", "Q3"}
	} else {
		sitesToQuery = []string{siteID}
	}

	books := make([]models.BookWithAvailability, 0)

	for rows.Next() {
		var book models.BookWithAvailability
		err := rows.Scan(&book.ISBN, &book.TenSach, &book.TacGia)
		if err != nil {
			continue
		}

		// Count availability across required sites
		var totalCount, availableCount, borrowedCount int

		for _, site := range sitesToQuery {
			siteConn, err := r.GetConnection(site)
			if err != nil {
				continue
			}

			// Count total copies
			countQuery := "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ?"
			var siteTotal int
			siteConn.QueryRow(countQuery, book.ISBN, site).Scan(&siteTotal)
			totalCount += siteTotal

			// Count available copies
			availQuery := "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ? AND TinhTrang = 'Có sẵn'"
			var siteAvailable int
			siteConn.QueryRow(availQuery, book.ISBN, site).Scan(&siteAvailable)
			availableCount += siteAvailable
		}

		borrowedCount = totalCount - availableCount

		book.TotalCount = totalCount
		book.AvailableCount = availableCount
		book.BorrowedCount = borrowedCount

		books = append(books, book)
	}

	return &PaginatedResult{
		Data:       books,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetBookCopiesPaginated gets book copies with pagination support
func (r *BookRepository) GetBookCopiesPaginated(siteID string, pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Build base queries
	var baseQuery, countQuery string
	var args []interface{}

	if searchTerm != "" {
		baseQuery = `
			SELECT qs.MaQuyenSach, qs.ISBN, qs.MaCN, qs.TinhTrang 
			FROM QUYENSACH qs 
			JOIN SACH s ON qs.ISBN = s.ISBN 
			WHERE s.TenSach LIKE ? OR s.TacGia LIKE ? OR qs.ISBN LIKE ?`
		countQuery = `
			SELECT COUNT(*) 
			FROM QUYENSACH qs 
			JOIN SACH s ON qs.ISBN = s.ISBN 
			WHERE s.TenSach LIKE ? OR s.TacGia LIKE ? OR qs.ISBN LIKE ?`
		searchPattern := "%" + searchTerm + "%"
		args = []interface{}{searchPattern, searchPattern, searchPattern}
	} else {
		baseQuery = "SELECT MaQuyenSach, ISBN, MaCN, TinhTrang FROM QUYENSACH"
		countQuery = "SELECT COUNT(*) FROM QUYENSACH"
	}

	// Get total count
	totalCount, err := r.GetTotalCount(conn, countQuery, args...)
	if err != nil {
		return nil, err
	}

	// Get paginated data
	paginatedQuery := r.BuildPaginatedQuery(baseQuery, pagination)

	rows, err := conn.Query(paginatedQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var copies []models.QuyenSach
	for rows.Next() {
		var copy models.QuyenSach
		err := rows.Scan(&copy.MaQuyenSach, &copy.ISBN, &copy.MaCN, &copy.TinhTrang)
		if err != nil {
			return nil, err
		}
		copies = append(copies, copy)
	}

	return &PaginatedResult{
		Data:       copies,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetBooks gets all books (replicated data) from any site
func (r *BookRepository) GetBooks(siteID string) ([]models.Sach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT ISBN, TenSach, TacGia FROM SACH ORDER BY TenSach"
	rows, err := conn.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var books []models.Sach
	for rows.Next() {
		var book models.Sach
		err := rows.Scan(&book.ISBN, &book.TenSach, &book.TacGia)
		if err != nil {
			return nil, err
		}
		books = append(books, book)
	}

	return books, nil
}

// GetBooksWithAvailability gets all books with availability count
func (r *BookRepository) GetBooksWithAvailability(siteID string, userRole string) ([]models.BookWithAvailability, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Query for books with availability count
	var sitesToQuery []string

	if userRole == "QUANLY" {
		// Manager sees system-wide data
		sitesToQuery = []string{"Q1", "Q3"}
	} else {
		// Librarian sees only local data
		sitesToQuery = []string{siteID}
	}

	books := make([]models.BookWithAvailability, 0)

	// Get all book titles first
	titleQuery := "SELECT ISBN, TenSach, TacGia FROM SACH ORDER BY TenSach"
	rows, err := conn.Query(titleQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var book models.BookWithAvailability
		err := rows.Scan(&book.ISBN, &book.TenSach, &book.TacGia)
		if err != nil {
			continue
		}

		// Count availability across required sites
		var totalCount, availableCount, borrowedCount int

		for _, site := range sitesToQuery {
			siteConn, err := r.GetConnection(site)
			if err != nil {
				continue
			}

			// Count total copies
			countQuery := "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ?"
			var siteTotal int
			siteConn.QueryRow(countQuery, book.ISBN, site).Scan(&siteTotal)
			totalCount += siteTotal

			// Count available copies
			availQuery := "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ? AND TinhTrang = 'Có sẵn'"
			var siteAvailable int
			siteConn.QueryRow(availQuery, book.ISBN, site).Scan(&siteAvailable)
			availableCount += siteAvailable
		}

		borrowedCount = totalCount - availableCount

		book.TotalCount = totalCount
		book.AvailableCount = availableCount
		book.BorrowedCount = borrowedCount

		books = append(books, book)
	}

	return books, nil
}

// GetBookCopies gets book copies from local site (fragmented data)
func (r *BookRepository) GetBookCopies(siteID string) ([]models.QuyenSach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT MaQuyenSach, ISBN, MaCN, TinhTrang FROM QUYENSACH ORDER BY MaQuyenSach"
	rows, err := conn.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var copies []models.QuyenSach
	for rows.Next() {
		var copy models.QuyenSach
		err := rows.Scan(&copy.MaQuyenSach, &copy.ISBN, &copy.MaCN, &copy.TinhTrang)
		if err != nil {
			return nil, err
		}
		copies = append(copies, copy)
	}

	return copies, nil
}

// SearchBooksSystemWide implements FR7 - distributed book search
func (r *BookRepository) SearchBooksSystemWide(tenSach, tacGia, isbn string) ([]models.BookSearchResult, error) {
	// Get connection to any site (using Q1) for book search
	conn, err := r.GetConnection("Q1")
	if err != nil {
		return nil, err
	}

	// Call the stored procedure for system-wide book search
	query := "EXEC sp_TimKiemSachToanHeThong @TenSach = ?, @TacGia = ?, @ISBN = ?"
	rows, err := conn.Query(query,
		sql.NullString{String: tenSach, Valid: tenSach != ""},
		sql.NullString{String: tacGia, Valid: tacGia != ""},
		sql.NullString{String: isbn, Valid: isbn != ""})
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.BookSearchResult
	for rows.Next() {
		var result models.BookSearchResult
		var maCN string
		var tenCN string

		err := rows.Scan(
			&result.Sach.ISBN,
			&result.Sach.TenSach,
			&result.Sach.TacGia,
			&maCN,
			&tenCN,
			&result.SoLuongCo,
		)
		if err != nil {
			return nil, err
		}

		// Group by book and aggregate branch info
		found := false
		for i := range results {
			if results[i].Sach.ISBN == result.Sach.ISBN {
				results[i].ChiNhanh = append(results[i].ChiNhanh, models.ChiNhanh{
					MaCN:  maCN,
					TenCN: tenCN,
				})
				found = true
				break
			}
		}

		if !found {
			result.ChiNhanh = []models.ChiNhanh{{MaCN: maCN, TenCN: tenCN}}
			results = append(results, result)
		}
	}

	return results, nil
}

// GetBookByISBN gets book details by ISBN
func (r *BookRepository) GetBookByISBN(isbn, siteID string) (*models.Sach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT ISBN, TenSach, TacGia FROM SACH WHERE ISBN = ?"
	var book models.Sach
	err = conn.QueryRow(query, isbn).Scan(&book.ISBN, &book.TenSach, &book.TacGia)
	if err != nil {
		return nil, err
	}

	return &book, nil
}

// GetAvailableBookCopy gets an available copy of a book at a specific site
func (r *BookRepository) GetAvailableBookCopy(isbn, siteID string) (*models.QuyenSach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT TOP 1 MaQuyenSach, ISBN, MaCN, TinhTrang 
		FROM QUYENSACH 
		WHERE ISBN = ? AND MaCN = ? AND TinhTrang = N'Có sẵn'
	`

	var copy models.QuyenSach
	err = conn.QueryRow(query, isbn, siteID).Scan(
		&copy.MaQuyenSach, &copy.ISBN, &copy.MaCN, &copy.TinhTrang)
	if err != nil {
		return nil, err
	}

	return &copy, nil
}

// QUYENSACH Management Methods (FR9) - ThuThu Operations

// CreateQuyenSach creates a new book copy using sp_ThuThu_CreateQuyenSach
func (r *BookRepository) CreateQuyenSach(quyenSach models.QuyenSach) error {
	conn, err := r.GetConnection(r.GetSiteForBranch(quyenSach.MaCN))
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_CreateQuyenSach @MaQuyenSach = ?, @ISBN = ?"
	_, err = conn.Exec(query, quyenSach.MaQuyenSach, quyenSach.ISBN)
	return err
}

// ReadQuyenSach retrieves book copy information using sp_ThuThu_ReadQuyenSach
func (r *BookRepository) ReadQuyenSach(maQuyenSach string, siteID string) (*models.QuyenSach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "EXEC sp_ThuThu_ReadQuyenSach @MaQuyenSach = ?"
	row := conn.QueryRow(query, maQuyenSach)

	var quyenSach models.QuyenSach
	err = row.Scan(&quyenSach.MaQuyenSach, &quyenSach.ISBN, &quyenSach.MaCN, &quyenSach.TinhTrang)
	if err != nil {
		return nil, err
	}

	return &quyenSach, nil
}

// UpdateQuyenSach updates book copy information using sp_ThuThu_UpdateQuyenSach
func (r *BookRepository) UpdateQuyenSach(quyenSach models.QuyenSach) error {
	conn, err := r.GetConnection(r.GetSiteForBranch(quyenSach.MaCN))
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_UpdateQuyenSach @MaQuyenSach = ?, @TinhTrang = ?"
	_, err = conn.Exec(query, quyenSach.MaQuyenSach, quyenSach.TinhTrang)
	return err
}

// DeleteQuyenSach deletes a book copy using sp_ThuThu_DeleteQuyenSach
func (r *BookRepository) DeleteQuyenSach(maQuyenSach string, siteID string) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_DeleteQuyenSach @MaQuyenSach = ?"
	_, err = conn.Exec(query, maQuyenSach)
	return err
}

// SACH Management Methods (FR10) - QuanLy Operations with 2PC

// CreateSach creates a new book using 2PC protocol (replicated table)
func (r *BookRepository) CreateSach(sach models.Sach, transactionID string) error {
	// Phase 1: Prepare on all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return err
	}

	for siteID, conn := range connections {
		query := "EXEC sp_QuanLy_PrepareCreateSach @ISBN = ?, @TenSach = ?, @TacGia = ?, @TransactionId = ?"
		_, err = conn.Exec(query, sach.ISBN, sach.TenSach, sach.TacGia, transactionID)
		if err != nil {
			// Rollback all sites if prepare fails
			r.rollbackCreateSach(connections, transactionID)
			return fmt.Errorf("prepare failed on site %s: %w", siteID, err)
		}
	}

	// Phase 2: Commit on all sites
	for siteID, conn := range connections {
		query := "EXEC sp_QuanLy_CommitCreateSach @ISBN = ?, @TenSach = ?, @TacGia = ?, @TransactionId = ?"
		_, err = conn.Exec(query, sach.ISBN, sach.TenSach, sach.TacGia, transactionID)
		if err != nil {
			return fmt.Errorf("commit failed on site %s: %w", siteID, err)
		}
	}

	return nil
}

// rollbackCreateSach performs rollback on all sites
func (r *BookRepository) rollbackCreateSach(connections map[string]*sql.DB, transactionID string) {
	for _, conn := range connections {
		// Execute rollback stored procedure if exists
		conn.Exec("EXEC sp_QuanLy_RollbackCreateSach @TransactionId = ?", transactionID)
	}
}

// ReadSach retrieves book information using sp_QuanLy_ReadSach
func (r *BookRepository) ReadSach(isbn string, siteID string) (*models.Sach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "EXEC sp_QuanLy_ReadSach @ISBN = ?"
	row := conn.QueryRow(query, isbn)

	var sach models.Sach
	err = row.Scan(&sach.ISBN, &sach.TenSach, &sach.TacGia)
	if err != nil {
		return nil, err
	}

	return &sach, nil
}

// SearchAvailableBooks implements FR7 using sp_QuanLy_SearchAvailableBooks
func (r *BookRepository) SearchAvailableBooks(tenSach string) ([]models.BookSearchResult, error) {
	conn, err := r.GetConnection("Q1") // Use any site for manager query
	if err != nil {
		return nil, err
	}

	query := "EXEC sp_QuanLy_SearchAvailableBooks @TenSach = ?"
	rows, err := conn.Query(query, tenSach)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	resultsMap := make(map[string]*models.BookSearchResult)

	for rows.Next() {
		var isbn, tenSachResult, tacGia, maCN, tenCN, diaChi string
		var soLuongCo int

		err := rows.Scan(&isbn, &tenSachResult, &tacGia, &maCN, &tenCN, &diaChi, &soLuongCo)
		if err != nil {
			return nil, err
		}

		if result, exists := resultsMap[isbn]; exists {
			// Add branch to existing result
			result.ChiNhanh = append(result.ChiNhanh, models.ChiNhanh{
				MaCN:   maCN,
				TenCN:  tenCN,
				DiaChi: diaChi,
			})
			result.SoLuongCo += soLuongCo
		} else {
			// Create new result
			resultsMap[isbn] = &models.BookSearchResult{
				Sach: models.Sach{
					ISBN:    isbn,
					TenSach: tenSachResult,
					TacGia:  tacGia,
				},
				ChiNhanh: []models.ChiNhanh{
					{
						MaCN:   maCN,
						TenCN:  tenCN,
						DiaChi: diaChi,
					},
				},
				SoLuongCo: soLuongCo,
			}
		}
	}

	var results []models.BookSearchResult
	for _, result := range resultsMap {
		results = append(results, *result)
	}

	return results, nil
}
