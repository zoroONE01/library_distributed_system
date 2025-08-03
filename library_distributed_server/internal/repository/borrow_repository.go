package repository

import (
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
)

type BorrowRepository struct {
	*BaseRepository
}

func NewBorrowRepository(config *config.Config) *BorrowRepository {
	return &BorrowRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// CreateBorrow implements FR2 - Lập phiếu mượn sách using sp_ThuThu_CreatePhieuMuon
func (r *BorrowRepository) CreateBorrow(maDG, maQuyenSach, maCN string) (*models.PhieuMuon, error) {
	conn, err := r.GetConnection(maCN)
	if err != nil {
		return nil, err
	}

	// Call stored procedure sp_ThuThu_CreatePhieuMuon
	query := "EXEC sp_ThuThu_CreatePhieuMuon @MaDG = ?, @MaQuyenSach = ?"
	_, err = conn.Exec(query, maDG, maQuyenSach)
	if err != nil {
		return nil, fmt.Errorf("failed to create borrow record: %w", err)
	}

	// Get the created borrow record
	return r.GetLatestBorrow(maDG, maCN)
}

// ReturnBook implements FR3 - Ghi nhận trả sách using sp_ThuThu_ReturnBook
func (r *BorrowRepository) ReturnBook(maPhieuMuon int, maQuyenSach, siteID string) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	// Call stored procedure sp_ThuThu_ReturnBook
	query := "EXEC sp_ThuThu_ReturnBook @MaQuyenSach = ?"
	_, err = conn.Exec(query, maQuyenSach)
	if err != nil {
		return fmt.Errorf("failed to return book: %w", err)
	}

	return nil
}

// ReadPhieuMuon retrieves borrow record using sp_ThuThu_ReadPhieuMuon
func (r *BorrowRepository) ReadPhieuMuon(maPM int, siteID string) (*models.PhieuMuon, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "EXEC sp_ThuThu_ReadPhieuMuon @MaPM = ?"
	row := conn.QueryRow(query, maPM)

	var phieuMuon models.PhieuMuon
	err = row.Scan(
		&phieuMuon.MaPM,
		&phieuMuon.MaDG,
		&phieuMuon.MaQuyenSach,
		&phieuMuon.MaCN,
		&phieuMuon.NgayMuon,
		&phieuMuon.NgayTra,
	)
	if err != nil {
		return nil, err
	}

	return &phieuMuon, nil
}

// GetBorrows gets borrow records for a site (FR4 - Tra cứu cục bộ)
func (r *BorrowRepository) GetBorrows(siteID string) ([]models.PhieuMuon, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON 
		ORDER BY NgayMuon DESC
	`

	rows, err := conn.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var borrows []models.PhieuMuon
	for rows.Next() {
		var borrow models.PhieuMuon
		err := rows.Scan(
			&borrow.MaPM,
			&borrow.MaDG,
			&borrow.MaQuyenSach,
			&borrow.MaCN,
			&borrow.NgayMuon,
			&borrow.NgayTra,
		)
		if err != nil {
			return nil, err
		}
		borrows = append(borrows, borrow)
	}

	return borrows, nil
}

// GetSystemStats implements FR6 - Thống kê toàn hệ thống using sp_QuanLy_GetSiteStatistics
func (r *BorrowRepository) GetSystemStats() (*models.SystemStats, error) {
	// Get statistics from all sites
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, err
	}

	stats := &models.SystemStats{
		StatsBySite: make(map[string]models.SiteStats),
	}

	for siteID, conn := range connections {
		// Call stored procedure sp_QuanLy_GetSiteStatistics
		row := conn.QueryRow("EXEC sp_QuanLy_GetSiteStatistics")

		var siteStats models.SiteStats
		err := row.Scan(
			&siteStats.BooksOnLoan,
			&siteStats.TotalBooks,
			&siteStats.TotalReaders,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to get stats from site %s: %w", siteID, err)
		}

		siteStats.SiteID = siteID
		stats.StatsBySite[siteID] = siteStats
		stats.TotalBooksOnLoan += siteStats.BooksOnLoan
	}

	return stats, nil
}

// GetLatestBorrow gets the most recent borrow record for a reader
func (r *BorrowRepository) GetLatestBorrow(maDG, siteID string) (*models.PhieuMuon, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT TOP 1 MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra
		FROM PHIEUMUON 
		WHERE MaDG = ?
		ORDER BY NgayMuon DESC
	`

	var borrow models.PhieuMuon
	err = conn.QueryRow(query, maDG).Scan(
		&borrow.MaPM,
		&borrow.MaDG,
		&borrow.MaQuyenSach,
		&borrow.MaCN,
		&borrow.NgayMuon,
		&borrow.NgayTra,
	)
	if err != nil {
		return nil, err
	}

	return &borrow, nil
}
