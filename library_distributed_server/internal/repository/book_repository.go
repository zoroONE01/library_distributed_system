package repository

import (
	"context"
	"database/sql"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"sync"
)

type BookRepository struct {
	*BaseRepository
}

func NewBookRepository(config *config.Config) *BookRepository {
	return &BookRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

func (r *BookRepository) GetBooks(ctx context.Context, siteID string) ([]models.Sach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}
	query := "SELECT ISBN, TenSach, TacGia FROM SACH"
	rows, err := conn.QueryContext(ctx, query)
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

func (r *BookRepository) GetBookCopies(ctx context.Context, siteID string) ([]models.QuyenSach, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}
	query := "SELECT MaQuyenSach, ISBN, MaCN, TinhTrang FROM QUYENSACH WHERE MaCN = ?"
	rows, err := conn.QueryContext(ctx, query, siteID)
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

func (r *BookRepository) SearchBooksByTitle(ctx context.Context, title string) ([]models.BookSearchResult, error) {
	books, err := r.searchBooksInReplicatedTable(ctx, title)
	if err != nil {
		return nil, err
	}
	var results []models.BookSearchResult
	availability, err := r.getBookAvailabilityAllSites(ctx, books)
	if err != nil {
		return nil, err
	}
	for _, book := range books {
		result := models.BookSearchResult{
			Sach:      book,
			ChiNhanh:  []models.ChiNhanh{},
			SoLuongCo: 0,
		}
		for siteID, count := range availability[book.ISBN] {
			if count > 0 {
				branch, err := r.getBranchInfo(ctx, siteID)
				if err == nil {
					result.ChiNhanh = append(result.ChiNhanh, branch)
					result.SoLuongCo += count
				}
			}
		}
		if result.SoLuongCo > 0 {
			results = append(results, result)
		}
	}
	return results, nil
}

func (r *BookRepository) searchBooksInReplicatedTable(ctx context.Context, title string) ([]models.Sach, error) {
	conn, err := r.GetConnection(r.config.Sites[0].SiteID)
	if err != nil {
		return nil, err
	}
	query := "SELECT ISBN, TenSach, TacGia FROM SACH WHERE TenSach LIKE ?"
	rows, err := conn.QueryContext(ctx, query, "%"+title+"%")
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

func (r *BookRepository) getBookAvailabilityAllSites(ctx context.Context, books []models.Sach) (map[string]map[string]int, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, err
	}
	results := make(map[string]map[string]int)
	var wg sync.WaitGroup
	mu := &sync.Mutex{}
	for _, book := range books {
		results[book.ISBN] = make(map[string]int)
		for siteID, conn := range connections {
			wg.Add(1)
			go func(isbn, siteID string, conn *sql.DB) {
				defer wg.Done()
				query := "SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND TinhTrang = N'Có sẵn'"
				var count int
				err := conn.QueryRowContext(ctx, query, isbn).Scan(&count)
				mu.Lock()
				results[isbn][siteID] = count
				mu.Unlock()
				_ = err // ignore error for demo
			}(book.ISBN, siteID, conn)
		}
	}
	wg.Wait()
	return results, nil
}

func (r *BookRepository) getBranchInfo(ctx context.Context, siteID string) (models.ChiNhanh, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return models.ChiNhanh{}, err
	}
	query := "SELECT MaCN, TenCN, DiaChi FROM CHINHANH WHERE MaCN = ?"
	var branch models.ChiNhanh
	err = conn.QueryRowContext(ctx, query, siteID).Scan(&branch.MaCN, &branch.TenCN, &branch.DiaChi)
	return branch, err
}
