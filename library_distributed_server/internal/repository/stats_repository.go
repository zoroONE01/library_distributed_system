package repository

import (
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
	"time"
)

type StatsRepository struct {
	*BaseRepository
}

func NewStatsRepository(config *config.Config) *StatsRepository {
	return &StatsRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// GetReadersWithStatsPaginated gets readers with borrowing statistics with pagination
func (r *StatsRepository) GetReadersWithStatsPaginated(siteID string, userRole string, pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	var sitesToQuery []string
	if userRole == "QUANLY" {
		sitesToQuery = []string{"Q1", "Q3"}
	} else {
		sitesToQuery = []string{siteID}
	}

	var allReaders []models.ReaderWithStats

	// Collect readers from all required sites
	for _, site := range sitesToQuery {
		siteConn, err := r.GetConnection(site)
		if err != nil {
			continue
		}

		// Build query based on search term
		var readerQuery string
		var args []interface{}

		if searchTerm != "" {
			readerQuery = `
				SELECT MaDG, HoTen, MaCN_DangKy
				FROM DOCGIA 
				WHERE (HoTen LIKE ? OR MaDG LIKE ?) AND MaCN_DangKy = ?
				ORDER BY HoTen
			`
			searchPattern := "%" + searchTerm + "%"
			args = []interface{}{searchPattern, searchPattern, site}
		} else {
			readerQuery = `
				SELECT MaDG, HoTen, MaCN_DangKy
				FROM DOCGIA 
				WHERE MaCN_DangKy = ?
				ORDER BY HoTen
			`
			args = []interface{}{site}
		}

		rows, err := siteConn.Query(readerQuery, args...)
		if err != nil {
			continue
		}

		for rows.Next() {
			var reader models.ReaderWithStats
			err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
			if err != nil {
				continue
			}

			// Get borrowing statistics
			statsQuery := `
				SELECT 
					COUNT(*) as total_borrowed,
					COUNT(CASE WHEN NgayTra IS NULL THEN 1 END) as current_borrowed,
					COUNT(CASE WHEN NgayTra IS NULL AND DATEDIFF(day, NgayMuon, GETDATE()) > 30 THEN 1 END) as overdue,
					MAX(NgayMuon) as last_borrow
				FROM PHIEUMUON
				WHERE MaDG = ? AND MaCN = ?
			`

			var totalBorrowed, currentBorrowed, overdueBooks int
			var lastBorrowTime *time.Time

			err = siteConn.QueryRow(statsQuery, reader.MaDG, site).Scan(
				&totalBorrowed, &currentBorrowed, &overdueBooks, &lastBorrowTime)
			if err == nil {
				reader.TotalBorrowed = totalBorrowed
				reader.CurrentBorrowed = currentBorrowed
				reader.OverdueBooks = overdueBooks

				if lastBorrowTime != nil {
					reader.LastBorrowDate = lastBorrowTime.Format("2006-01-02")
				} else {
					reader.LastBorrowDate = ""
				}
			}

			allReaders = append(allReaders, reader)
		}
		rows.Close()
	}

	totalCount := len(allReaders)

	// Apply pagination to combined results
	start := pagination.CalculateOffset()
	end := start + pagination.Size
	if start >= len(allReaders) {
		allReaders = []models.ReaderWithStats{}
	} else {
		if end > len(allReaders) {
			end = len(allReaders)
		}
		allReaders = allReaders[start:end]
	}

	return &PaginatedResult{
		Data:       allReaders,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetReadersWithStats gets readers with borrowing statistics
func (r *StatsRepository) GetReadersWithStats(siteID string, userRole string) ([]models.ReaderWithStats, error) {
	var sitesToQuery []string
	if userRole == "QUANLY" {
		sitesToQuery = []string{"Q1", "Q3"}
	} else {
		sitesToQuery = []string{siteID}
	}

	readersMap := make(map[string]*models.ReaderWithStats)

	for _, site := range sitesToQuery {
		siteConn, err := r.GetConnection(site)
		if err != nil {
			continue
		}

		// Get readers for this site
		readerQuery := `
			SELECT MaDG, HoTen, MaCN_DangKy
			FROM DOCGIA 
			WHERE MaCN = ?
			ORDER BY HoTen
		`

		rows, err := siteConn.Query(readerQuery, site)
		if err != nil {
			continue
		}

		for rows.Next() {
			var reader models.ReaderWithStats
			err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
			if err != nil {
				continue
			}

			// Get borrowing statistics
			statsQuery := `
				SELECT 
					COUNT(*) as total_borrowed,
					COUNT(CASE WHEN NgayTra IS NULL THEN 1 END) as current_borrowed,
					COUNT(CASE WHEN NgayTra IS NULL AND DATEDIFF(day, NgayMuon, GETDATE()) > 30 THEN 1 END) as overdue,
					MAX(NgayMuon) as last_borrow
				FROM PHIEUMUON pm
				WHERE pm.MaDocGia = ? AND pm.MaCN = ?
			`

			var totalBorrowed, currentBorrowed, overdueBooks int
			var lastBorrowTime *time.Time

			err = siteConn.QueryRow(statsQuery, reader.MaDG, site).Scan(
				&totalBorrowed, &currentBorrowed, &overdueBooks, &lastBorrowTime)
			if err == nil {
				reader.TotalBorrowed = totalBorrowed
				reader.CurrentBorrowed = currentBorrowed
				reader.OverdueBooks = overdueBooks

				if lastBorrowTime != nil {
					reader.LastBorrowDate = lastBorrowTime.Format("2006-01-02")
				} else {
					reader.LastBorrowDate = ""
				}
			}

			readersMap[reader.MaDG] = &reader
		}
		rows.Close()
	}

	// Convert map to slice
	readers := make([]models.ReaderWithStats, 0, len(readersMap))
	for _, reader := range readersMap {
		readers = append(readers, *reader)
	}

	return readers, nil
}

// GetSystemStats gets comprehensive system statistics
func (r *StatsRepository) GetSystemStats(userRole string) (*models.SystemStatsResponse, error) {
	if userRole != "QUANLY" {
		return nil, fmt.Errorf("only managers can access system statistics")
	}

	stats := &models.SystemStatsResponse{
		GeneratedAt: time.Now().Format(time.RFC3339),
		SiteStats:   make([]models.SiteStats, 0),
	}

	sitesToQuery := []string{"Q1", "Q3"}

	for _, site := range sitesToQuery {
		siteConn, err := r.GetConnection(site)
		if err != nil {
			continue
		}

		var siteStats models.SiteStats
		siteStats.SiteID = site

		// Get total books count (from replicated SACH table)
		siteConn.QueryRow("SELECT COUNT(*) FROM SACH").Scan(&stats.TotalBooks)

		// Get site-specific statistics
		siteConn.QueryRow("SELECT COUNT(*) FROM QUYENSACH WHERE MaCN = ?", site).Scan(&siteStats.TotalBooks)
		siteConn.QueryRow("SELECT COUNT(*) FROM DOCGIA WHERE MaCN = ?", site).Scan(&siteStats.TotalReaders)
		siteConn.QueryRow("SELECT COUNT(*) FROM PHIEUMUON WHERE MaCN = ? AND NgayTra IS NULL", site).Scan(&siteStats.BooksOnLoan)

		stats.TotalCopies += siteStats.TotalBooks
		stats.TotalReaders += siteStats.TotalReaders
		stats.ActiveBorrows += siteStats.BooksOnLoan

		// Calculate overdue books for system total (not stored in SiteStats)
		var overdueCount int
		siteConn.QueryRow("SELECT COUNT(*) FROM PHIEUMUON WHERE MaCN = ? AND NgayTra IS NULL AND DATEDIFF(day, NgayMuon, GETDATE()) > 30", site).Scan(&overdueCount)
		stats.OverdueBooks += overdueCount

		stats.SiteStats = append(stats.SiteStats, siteStats)
	}

	// Get popular books (most borrowed)
	popularBooks, _ := r.getPopularBooks()
	stats.PopularBooks = popularBooks

	return stats, nil
}

// getPopularBooks gets most borrowed books across all sites
func (r *StatsRepository) getPopularBooks() ([]models.BookWithAvailability, error) {
	books := make([]models.BookWithAvailability, 0)

	// Get connection to any site to access SACH table
	conn, err := r.GetConnection("Q1")
	if err != nil {
		return books, err
	}

	// Query for books with borrow counts
	query := `
		SELECT TOP 5 s.ISBN, s.TenSach, s.TacGia, 
			   COUNT(qm.QuyenSo) as borrow_count
		FROM SACH s
		LEFT JOIN QUYENSACH qs ON s.ISBN = qs.ISBN
		LEFT JOIN QUYENMUON qm ON qs.QuyenSo = qm.QuyenSo
		GROUP BY s.ISBN, s.TenSach, s.TacGia
		ORDER BY borrow_count DESC
	`

	rows, err := conn.Query(query)
	if err != nil {
		return books, err
	}
	defer rows.Close()

	for rows.Next() {
		var book models.BookWithAvailability
		var borrowCount int

		err := rows.Scan(&book.ISBN, &book.TenSach, &book.TacGia, &borrowCount)
		if err != nil {
			continue
		}

		// Get current availability counts
		for _, site := range []string{"Q1", "Q3"} {
			siteConn, err := r.GetConnection(site)
			if err != nil {
				continue
			}

			var total, available int
			siteConn.QueryRow("SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ?", book.ISBN, site).Scan(&total)
			siteConn.QueryRow("SELECT COUNT(*) FROM QUYENSACH WHERE ISBN = ? AND MaCN = ? AND TinhTrang = 'Có sẵn'", book.ISBN, site).Scan(&available)

			book.TotalCount += total
			book.AvailableCount += available
		}

		book.BorrowedCount = book.TotalCount - book.AvailableCount
		books = append(books, book)
	}

	return books, nil
}
