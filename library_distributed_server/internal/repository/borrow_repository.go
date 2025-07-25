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

// CreateBorrow implements FR2 - Lập phiếu mượn sách
func (r *BorrowRepository) CreateBorrow(maDG, maQuyenSach, maCN string) (*models.PhieuMuon, error) {
	conn, err := r.GetConnection(maCN)
	if err != nil {
		return nil, err
	}

	// Call stored procedure sp_LapPhieuMuon
	query := "EXEC sp_LapPhieuMuon @MaDG = ?, @MaQuyenSach = ?, @MaCN = ?"
	_, err = conn.Exec(query, maDG, maQuyenSach, maCN)
	if err != nil {
		return nil, fmt.Errorf("failed to create borrow record: %w", err)
	}

	// Get the created borrow record
	return r.GetLatestBorrow(maDG, maCN)
}

// ReturnBook implements FR3 - Ghi nhận trả sách
func (r *BorrowRepository) ReturnBook(maPhieuMuon int, maQuyenSach, siteID string) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	// Call stored procedure sp_GhiNhanTraSach
	var query string
	var args []interface{}

	if maPhieuMuon > 0 {
		query = "EXEC sp_GhiNhanTraSach @MaPhieuMuon = ?"
		args = []interface{}{maPhieuMuon}
	} else {
		query = "EXEC sp_GhiNhanTraSach @MaQuyenSach = ?"
		args = []interface{}{maQuyenSach}
	}

	_, err = conn.Exec(query, args...)
	if err != nil {
		return fmt.Errorf("failed to return book: %w", err)
	}

	return nil
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

// GetSystemStats implements FR6 - Thống kê toàn hệ thống
func (r *BorrowRepository) GetSystemStats() (*models.SystemStats, error) {
	// Use Q1 as coordinator site
	conn, err := r.GetConnection("Q1")
	if err != nil {
		return nil, err
	}

	// Call stored procedure sp_ThongKeToanHeThong
	rows, err := conn.Query("EXEC sp_ThongKeToanHeThong")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	stats := &models.SystemStats{
		StatsBySite: make(map[string]models.SiteStats),
	}

	for rows.Next() {
		var siteID string
		var booksOnLoan, totalBooks, totalReaders int

		err := rows.Scan(&siteID, &booksOnLoan, &totalBooks, &totalReaders)
		if err != nil {
			return nil, err
		}

		stats.StatsBySite[siteID] = models.SiteStats{
			SiteID:       siteID,
			BooksOnLoan:  booksOnLoan,
			TotalBooks:   totalBooks,
			TotalReaders: totalReaders,
		}

		stats.TotalBooksOnLoan += booksOnLoan
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

// GetReaderInfo gets reader information
func (r *BorrowRepository) GetReaderInfo(maDG, siteID string) (*models.DocGia, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA WHERE MaDG = ?"
	var reader models.DocGia
	err = conn.QueryRow(query, maDG).Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
	if err != nil {
		return nil, err
	}

	return &reader, nil
}
