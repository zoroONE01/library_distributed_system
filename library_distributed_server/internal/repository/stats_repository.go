package repository

import (
	"context"
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"log"
	"time"
)

// StatsRepository handles statistics operations using raw SQL queries
type StatsRepository struct {
	*BaseRepository
}

// StatsRepositoryInterface defines statistics-related operations with raw SQL
type StatsRepositoryInterface interface {
	// Site-specific statistics
	GetSiteStatistics(ctx context.Context, siteID string) (*models.SiteStats, error)
	GetSiteBookStatistics(ctx context.Context, siteID string) (map[string]interface{}, error)
	GetSiteReaderStatistics(ctx context.Context, siteID string) (map[string]interface{}, error)

	// System-wide statistics (Manager only)
	GetSystemStatistics(ctx context.Context) (*models.SystemStatsResponse, error)
	GetDistributedStatistics(ctx context.Context) (*models.SystemStats, error)
	GetPopularBooksAcrossSites(ctx context.Context, limit int) ([]*models.BookWithAvailability, error)

	// Performance analytics
	GetBorrowTrends(ctx context.Context, siteID string, days int) ([]map[string]interface{}, error)
	GetOverdueAnalytics(ctx context.Context, siteID string) (map[string]interface{}, error)
	GetReaderEngagementStats(ctx context.Context, siteID string) (map[string]interface{}, error)

	// Health monitoring
	GetSystemHealth(ctx context.Context) (map[string]interface{}, error)
	GetSiteHealth(ctx context.Context, siteID string) (map[string]interface{}, error)
}

// NewStatsRepository creates a new statistics repository with raw SQL
func NewStatsRepository(config *config.Config) StatsRepositoryInterface {
	return &StatsRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// GetSiteStatistics retrieves comprehensive statistics for a specific site (FR6)
func (r *StatsRepository) GetSiteStatistics(ctx context.Context, siteID string) (*models.SiteStats, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	stats := &models.SiteStats{
		SiteID: siteID,
	}

	// Get books on loan
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL
	`, siteID).Scan(&stats.BooksOnLoan)
	if err != nil {
		return nil, fmt.Errorf("failed to get books on loan: %w", err)
	}

	// Get total books (book copies) in this site
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM QUYENSACH 
		WHERE MaCN = ?
	`, siteID).Scan(&stats.TotalBooks)
	if err != nil {
		return nil, fmt.Errorf("failed to get total books: %w", err)
	}

	// Get total readers registered in this site
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM DOCGIA 
		WHERE MaCN_DangKy = ?
	`, siteID).Scan(&stats.TotalReaders)
	if err != nil {
		return nil, fmt.Errorf("failed to get total readers: %w", err)
	}

	log.Printf("Site %s statistics: %d books on loan, %d total books, %d readers",
		siteID, stats.BooksOnLoan, stats.TotalBooks, stats.TotalReaders)

	return stats, nil
}

// GetSiteBookStatistics retrieves detailed book statistics for a site
func (r *StatsRepository) GetSiteBookStatistics(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	stats := make(map[string]interface{})

	// Total book copies
	var totalCopies int
	err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM QUYENSACH WHERE MaCN = ?", siteID).Scan(&totalCopies)
	if err != nil {
		return nil, fmt.Errorf("failed to get total copies: %w", err)
	}
	stats["totalCopies"] = totalCopies

	// Available copies
	var availableCopies int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM QUYENSACH 
		WHERE MaCN = ? AND TinhTrang = N'Có sẵn'
	`, siteID).Scan(&availableCopies)
	if err != nil {
		return nil, fmt.Errorf("failed to get available copies: %w", err)
	}
	stats["availableCopies"] = availableCopies

	// Borrowed copies
	var borrowedCopies int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM QUYENSACH 
		WHERE MaCN = ? AND TinhTrang = N'Đang được mượn'
	`, siteID).Scan(&borrowedCopies)
	if err != nil {
		return nil, fmt.Errorf("failed to get borrowed copies: %w", err)
	}
	stats["borrowedCopies"] = borrowedCopies

	// Unique book titles (ISBNs)
	var uniqueTitles int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(DISTINCT ISBN) 
		FROM QUYENSACH 
		WHERE MaCN = ?
	`, siteID).Scan(&uniqueTitles)
	if err != nil {
		return nil, fmt.Errorf("failed to get unique titles: %w", err)
	}
	stats["uniqueTitles"] = uniqueTitles

	// Utilization rate
	if totalCopies > 0 {
		utilizationRate := float64(borrowedCopies) / float64(totalCopies) * 100
		stats["utilizationRate"] = utilizationRate
	} else {
		stats["utilizationRate"] = 0.0
	}

	return stats, nil
}

// GetSiteReaderStatistics retrieves detailed reader statistics for a site
func (r *StatsRepository) GetSiteReaderStatistics(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	stats := make(map[string]interface{})

	// Total readers
	var totalReaders int
	err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM DOCGIA WHERE MaCN_DangKy = ?", siteID).Scan(&totalReaders)
	if err != nil {
		return nil, fmt.Errorf("failed to get total readers: %w", err)
	}
	stats["totalReaders"] = totalReaders

	// Active readers (have borrowed at least one book)
	var activeReaders int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(DISTINCT MaDG) 
		FROM PHIEUMUON 
		WHERE MaCN = ?
	`, siteID).Scan(&activeReaders)
	if err != nil {
		return nil, fmt.Errorf("failed to get active readers: %w", err)
	}
	stats["activeReaders"] = activeReaders

	// Readers with current borrows
	var readersWithCurrentBorrows int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(DISTINCT MaDG) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL
	`, siteID).Scan(&readersWithCurrentBorrows)
	if err != nil {
		return nil, fmt.Errorf("failed to get readers with current borrows: %w", err)
	}
	stats["readersWithCurrentBorrows"] = readersWithCurrentBorrows

	// Readers with overdue books
	var readersWithOverdue int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(DISTINCT MaDG) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL 
			AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
	`, siteID).Scan(&readersWithOverdue)
	if err != nil {
		return nil, fmt.Errorf("failed to get readers with overdue: %w", err)
	}
	stats["readersWithOverdue"] = readersWithOverdue

	// Average books per reader
	if totalReaders > 0 {
		var totalBorrows int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM PHIEUMUON WHERE MaCN = ?", siteID).Scan(&totalBorrows)
		if err != nil {
			return nil, fmt.Errorf("failed to get total borrows: %w", err)
		}
		avgBooksPerReader := float64(totalBorrows) / float64(totalReaders)
		stats["avgBooksPerReader"] = avgBooksPerReader
	} else {
		stats["avgBooksPerReader"] = 0.0
	}

	return stats, nil
}

// GetSystemStatistics retrieves comprehensive system-wide statistics (Manager only)
func (r *StatsRepository) GetSystemStatistics(ctx context.Context) (*models.SystemStatsResponse, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	response := &models.SystemStatsResponse{
		GeneratedAt: time.Now().Format("2006-01-02T15:04:05Z"),
	}

	var allSiteStats []models.SiteStats

	// Collect statistics from each site
	for siteID := range connections {
		siteStats, err := r.GetSiteStatistics(ctx, siteID)
		if err != nil {
			log.Printf("Error getting statistics from site %s: %v", siteID, err)
			continue
		}

		allSiteStats = append(allSiteStats, *siteStats)

		// Aggregate totals
		response.TotalCopies += siteStats.TotalBooks
		response.TotalReaders += siteStats.TotalReaders
		response.ActiveBorrows += siteStats.BooksOnLoan
	}

	response.SiteStats = allSiteStats

	// Get total unique book titles across all sites (from replicated SACH table)
	if len(connections) > 0 {
		// Use first available connection since SACH is replicated
		for _, db := range connections {
			err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM SACH").Scan(&response.TotalBooks)
			if err != nil {
				log.Printf("Error getting total books count: %v", err)
			}
			break // Only need to query one site for replicated data
		}
	}

	// Calculate overdue books across all sites
	for siteID, db := range connections {
		var siteOverdue int
		err = db.QueryRowContext(ctx, `
			SELECT COUNT(*) 
			FROM PHIEUMUON 
			WHERE MaCN = ? AND NgayTra IS NULL 
				AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
		`, siteID).Scan(&siteOverdue)
		if err != nil {
			log.Printf("Error getting overdue count from site %s: %v", siteID, err)
			continue
		}
		response.OverdueBooks += siteOverdue
	}

	// Get popular books across all sites
	popularBooks, err := r.GetPopularBooksAcrossSites(ctx, 10)
	if err != nil {
		log.Printf("Error getting popular books: %v", err)
	} else {
		// Convert from []*models.BookWithAvailability to []models.BookWithAvailability
		for _, book := range popularBooks {
			if book != nil {
				response.PopularBooks = append(response.PopularBooks, *book)
			}
		}
	}

	return response, nil
}

// GetDistributedStatistics retrieves system statistics in legacy format
func (r *StatsRepository) GetDistributedStatistics(ctx context.Context) (*models.SystemStats, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	stats := &models.SystemStats{
		StatsBySite: make(map[string]models.SiteStats),
	}

	// Collect statistics from each site
	for siteID := range connections {
		siteStats, err := r.GetSiteStatistics(ctx, siteID)
		if err != nil {
			log.Printf("Error getting statistics from site %s: %v", siteID, err)
			continue
		}

		stats.StatsBySite[siteID] = *siteStats
		stats.TotalBooksOnLoan += siteStats.BooksOnLoan
	}

	return stats, nil
}

// GetPopularBooksAcrossSites retrieves most popular books system-wide
func (r *StatsRepository) GetPopularBooksAcrossSites(ctx context.Context, limit int) ([]*models.BookWithAvailability, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	// Map to aggregate book statistics across sites
	bookStats := make(map[string]*models.BookWithAvailability)

	query := `
		SELECT 
			s.ISBN, s.TenSach, s.TacGia,
			COUNT(qs.MaQuyenSach) as TotalCount,
			SUM(CASE WHEN qs.TinhTrang = N'Có sẵn' THEN 1 ELSE 0 END) as AvailableCount,
			SUM(CASE WHEN qs.TinhTrang = N'Đang được mượn' THEN 1 ELSE 0 END) as BorrowedCount,
			COUNT(pm.MaPM) as BorrowCount
		FROM SACH s
		LEFT JOIN QUYENSACH qs ON s.ISBN = qs.ISBN AND qs.MaCN = ?
		LEFT JOIN PHIEUMUON pm ON qs.MaQuyenSach = pm.MaQuyenSach
		GROUP BY s.ISBN, s.TenSach, s.TacGia
		ORDER BY COUNT(pm.MaPM) DESC
	`

	for siteID, db := range connections {
		rows, err := db.QueryContext(ctx, query, siteID)
		if err != nil {
			log.Printf("Error querying popular books from site %s: %v", siteID, err)
			continue
		}
		defer rows.Close()

		for rows.Next() {
			var isbn, tenSach, tacGia string
			var totalCount, availableCount, borrowedCount, borrowCount int

			err := rows.Scan(&isbn, &tenSach, &tacGia, &totalCount, &availableCount, &borrowedCount, &borrowCount)
			if err != nil {
				log.Printf("Error scanning popular book from site %s: %v", siteID, err)
				continue
			}

			if book, exists := bookStats[isbn]; exists {
				// Aggregate counts
				book.TotalCount += totalCount
				book.AvailableCount += availableCount
				book.BorrowedCount += borrowedCount
			} else {
				// Create new entry
				bookStats[isbn] = &models.BookWithAvailability{
					ISBN:           isbn,
					TenSach:        tenSach,
					TacGia:         tacGia,
					TotalCount:     totalCount,
					AvailableCount: availableCount,
					BorrowedCount:  borrowedCount,
				}
			}
		}
	}

	// Convert map to slice and sort by popularity (could be enhanced with actual borrow counts)
	var books []*models.BookWithAvailability
	for _, book := range bookStats {
		if book.TotalCount > 0 { // Only include books that have copies
			books = append(books, book)
		}
	}

	// Simple sorting by total copies (in a real implementation, sort by actual borrow frequency)
	// TODO: Implement proper sorting by borrow frequency
	if len(books) > limit {
		books = books[:limit]
	}

	return books, nil
}

// GetBorrowTrends retrieves borrowing trends over specified days
func (r *StatsRepository) GetBorrowTrends(ctx context.Context, siteID string, days int) ([]map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	query := `
		SELECT 
			CONVERT(varchar, NgayMuon, 23) as BorrowDate,
			COUNT(*) as BorrowCount
		FROM PHIEUMUON 
		WHERE MaCN = ? 
			AND NgayMuon >= DATEADD(day, -?, GETDATE())
		GROUP BY CONVERT(varchar, NgayMuon, 23)
		ORDER BY BorrowDate
	`

	rows, err := db.QueryContext(ctx, query, siteID, days)
	if err != nil {
		return nil, fmt.Errorf("failed to query borrow trends: %w", err)
	}
	defer rows.Close()

	var trends []map[string]interface{}
	for rows.Next() {
		var date string
		var count int
		err := rows.Scan(&date, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan borrow trend: %w", err)
		}

		trend := map[string]interface{}{
			"date":        date,
			"borrowCount": count,
		}
		trends = append(trends, trend)
	}

	return trends, nil
}

// GetOverdueAnalytics retrieves overdue book analytics for a site
func (r *StatsRepository) GetOverdueAnalytics(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	analytics := make(map[string]interface{})

	// Total overdue books
	var totalOverdue int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL 
			AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
	`, siteID).Scan(&totalOverdue)
	if err != nil {
		return nil, fmt.Errorf("failed to get total overdue: %w", err)
	}
	analytics["totalOverdue"] = totalOverdue

	// Average overdue days
	var avgOverdueDays sql.NullFloat64
	err = db.QueryRowContext(ctx, `
		SELECT AVG(CAST(DATEDIFF(day, NgayMuon, GETDATE()) - 30 AS FLOAT))
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL 
			AND DATEDIFF(day, NgayMuon, GETDATE()) > 30
	`, siteID).Scan(&avgOverdueDays)
	if err != nil {
		return nil, fmt.Errorf("failed to get average overdue days: %w", err)
	}
	if avgOverdueDays.Valid {
		analytics["avgOverdueDays"] = avgOverdueDays.Float64
	} else {
		analytics["avgOverdueDays"] = 0
	}

	// Overdue rate
	var totalActive int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM PHIEUMUON 
		WHERE MaCN = ? AND NgayTra IS NULL
	`, siteID).Scan(&totalActive)
	if err != nil {
		return nil, fmt.Errorf("failed to get total active borrows: %w", err)
	}

	if totalActive > 0 {
		overdueRate := float64(totalOverdue) / float64(totalActive) * 100
		analytics["overdueRate"] = overdueRate
	} else {
		analytics["overdueRate"] = 0.0
	}

	return analytics, nil
}

// GetReaderEngagementStats retrieves reader engagement statistics
func (r *StatsRepository) GetReaderEngagementStats(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	stats := make(map[string]interface{})

	// Most active readers (top 5)
	query := `
		SELECT TOP 5
			dg.MaDG, dg.HoTen, COUNT(pm.MaPM) as BorrowCount
		FROM DOCGIA dg
		LEFT JOIN PHIEUMUON pm ON dg.MaDG = pm.MaDG
		WHERE dg.MaCN_DangKy = ?
		GROUP BY dg.MaDG, dg.HoTen
		ORDER BY COUNT(pm.MaPM) DESC
	`

	rows, err := db.QueryContext(ctx, query, siteID)
	if err != nil {
		return nil, fmt.Errorf("failed to query active readers: %w", err)
	}
	defer rows.Close()

	var activeReaders []map[string]interface{}
	for rows.Next() {
		var maDG, hoTen string
		var borrowCount int
		err := rows.Scan(&maDG, &hoTen, &borrowCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan active reader: %w", err)
		}

		reader := map[string]interface{}{
			"maDG":        maDG,
			"hoTen":       hoTen,
			"borrowCount": borrowCount,
		}
		activeReaders = append(activeReaders, reader)
	}
	stats["activeReaders"] = activeReaders

	// New readers this month
	var newReadersThisMonth int
	err = db.QueryRowContext(ctx, `
		SELECT COUNT(*) 
		FROM DOCGIA 
		WHERE MaCN_DangKy = ?
	`, siteID).Scan(&newReadersThisMonth)
	if err != nil {
		return nil, fmt.Errorf("failed to get new readers count: %w", err)
	}
	stats["newReadersThisMonth"] = newReadersThisMonth

	return stats, nil
}

// GetSystemHealth retrieves system-wide health metrics
func (r *StatsRepository) GetSystemHealth(ctx context.Context) (map[string]interface{}, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, fmt.Errorf("failed to get site connections: %w", err)
	}

	health := make(map[string]interface{})
	siteHealths := make(map[string]interface{})

	var totalSites int
	var healthySites int

	for siteID, db := range connections {
		siteHealth, err := r.getSiteHealthFromDB(ctx, db, siteID)
		if err != nil {
			log.Printf("Error getting health for site %s: %v", siteID, err)
			siteHealth = map[string]interface{}{
				"status": "unhealthy",
				"error":  err.Error(),
			}
		} else {
			healthySites++
		}

		siteHealths[siteID] = siteHealth
		totalSites++
	}

	health["totalSites"] = totalSites
	health["healthySites"] = healthySites
	health["unhealthySites"] = totalSites - healthySites
	health["systemStatus"] = "healthy"
	if healthySites < totalSites {
		health["systemStatus"] = "degraded"
	}
	if healthySites == 0 {
		health["systemStatus"] = "unhealthy"
	}

	health["sites"] = siteHealths
	health["lastChecked"] = time.Now().Format("2006-01-02T15:04:05Z")

	return health, nil
}

// GetSiteHealth retrieves health metrics for a specific site
func (r *StatsRepository) GetSiteHealth(ctx context.Context, siteID string) (map[string]interface{}, error) {
	db, err := r.GetConnection(siteID)
	if err != nil {
		return map[string]interface{}{
			"status": "unhealthy",
			"error":  fmt.Sprintf("failed to connect: %v", err),
		}, nil
	}

	return r.getSiteHealthFromDB(ctx, db, siteID)
}

// getSiteHealthFromDB retrieves health metrics from a database connection
func (r *StatsRepository) getSiteHealthFromDB(ctx context.Context, db *sql.DB, siteID string) (map[string]interface{}, error) {
	health := make(map[string]interface{})

	// Test database connectivity
	err := db.PingContext(ctx)
	if err != nil {
		return nil, fmt.Errorf("database ping failed: %w", err)
	}

	health["status"] = "healthy"
	health["siteID"] = siteID

	// Get basic table counts to ensure database integrity
	tables := []string{"SACH", "CHINHANH", "DOCGIA", "QUYENSACH", "PHIEUMUON"}
	tableCounts := make(map[string]int)

	for _, table := range tables {
		var count int
		query := fmt.Sprintf("SELECT COUNT(*) FROM %s", table)

		// Add site-specific WHERE clause for fragmented tables
		if table == "DOCGIA" {
			query += " WHERE MaCN_DangKy = ?"
		} else if table == "QUYENSACH" || table == "PHIEUMUON" {
			query += " WHERE MaCN = ?"
		}

		if table == "DOCGIA" || table == "QUYENSACH" || table == "PHIEUMUON" {
			err = db.QueryRowContext(ctx, query, siteID).Scan(&count)
		} else {
			err = db.QueryRowContext(ctx, query).Scan(&count)
		}

		if err != nil {
			log.Printf("Error querying table %s in site %s: %v", table, siteID, err)
			tableCounts[table] = -1 // Indicate error
		} else {
			tableCounts[table] = count
		}
	}

	health["tableCounts"] = tableCounts
	health["lastChecked"] = time.Now().Format("2006-01-02T15:04:05Z")

	return health, nil
}
