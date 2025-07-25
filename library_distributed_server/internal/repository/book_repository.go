package repository

import (
	"database/sql"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
)

type BookRepository struct {
	*BaseRepository
}

func NewBookRepository(config *config.Config) *BookRepository {
	return &BookRepository{
		BaseRepository: NewBaseRepository(config),
	}
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
