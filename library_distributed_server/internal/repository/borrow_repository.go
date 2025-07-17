package repository

import (
	"context"
	"errors"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"time"
)

type BorrowRepository struct {
	*BaseRepository
}

func NewBorrowRepository(config *config.Config) *BorrowRepository {
	return &BorrowRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

func (r *BorrowRepository) CreateBorrow(ctx context.Context, siteID, maDG, maQuyenSach string) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}
	// Check if book is available
	var status string
	err = conn.QueryRowContext(ctx, "SELECT TinhTrang FROM QUYENSACH WHERE MaQuyenSach = ?", maQuyenSach).Scan(&status)
	if err != nil {
		return err
	}
	if status != "Có sẵn" {
		return errors.New("Book is not available")
	}
	// Create borrow record
	_, err = conn.ExecContext(ctx, "INSERT INTO PHIEUMUON (MaDG, MaQuyenSach, MaCN, NgayMuon) VALUES (?, ?, ?, ?)", maDG, maQuyenSach, siteID, time.Now())
	if err != nil {
		return err
	}
	// Update book status
	_, err = conn.ExecContext(ctx, "UPDATE QUYENSACH SET TinhTrang = N'Đang được mượn' WHERE MaQuyenSach = ?", maQuyenSach)
	return err
}

func (r *BorrowRepository) ReturnBook(ctx context.Context, siteID string, maPM int) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}
	// Update return date
	_, err = conn.ExecContext(ctx, "UPDATE PHIEUMUON SET NgayTra = ? WHERE MaPM = ?", time.Now(), maPM)
	if err != nil {
		return err
	}
	// Get book id
	var maQuyenSach string
	err = conn.QueryRowContext(ctx, "SELECT MaQuyenSach FROM PHIEUMUON WHERE MaPM = ?", maPM).Scan(&maQuyenSach)
	if err != nil {
		return err
	}
	// Update book status
	_, err = conn.ExecContext(ctx, "UPDATE QUYENSACH SET TinhTrang = N'Có sẵn' WHERE MaQuyenSach = ?", maQuyenSach)
	return err
}

func (r *BorrowRepository) GetBorrows(ctx context.Context, siteID string) ([]models.PhieuMuon, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}
	query := "SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra FROM PHIEUMUON WHERE MaCN = ?"
	rows, err := conn.QueryContext(ctx, query, siteID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var borrows []models.PhieuMuon
	for rows.Next() {
		var pm models.PhieuMuon
		err := rows.Scan(&pm.MaPM, &pm.MaDG, &pm.MaQuyenSach, &pm.MaCN, &pm.NgayMuon, &pm.NgayTra)
		if err != nil {
			return nil, err
		}
		borrows = append(borrows, pm)
	}
	return borrows, nil
}

func (r *BorrowRepository) GetSystemStats(ctx context.Context) (models.SystemStats, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return models.SystemStats{}, err
	}
	stats := models.SystemStats{
		StatsBySite: make(map[string]models.SiteStats),
	}
	total := 0
	for siteID, conn := range connections {
		var booksOnLoan, totalBooks, totalReaders int
		// Count books on loan
		err := conn.QueryRowContext(ctx, "SELECT COUNT(*) FROM PHIEUMUON WHERE NgayTra IS NULL").Scan(&booksOnLoan)
		if err != nil {
			return models.SystemStats{}, err
		}
		// Count total books
		err = conn.QueryRowContext(ctx, "SELECT COUNT(*) FROM QUYENSACH").Scan(&totalBooks)
		if err != nil {
			return models.SystemStats{}, err
		}
		// Count total readers
		err = conn.QueryRowContext(ctx, "SELECT COUNT(*) FROM DOCGIA").Scan(&totalReaders)
		if err != nil {
			return models.SystemStats{}, err
		}
		stats.StatsBySite[siteID] = models.SiteStats{
			SiteID:       siteID,
			BooksOnLoan:  booksOnLoan,
			TotalBooks:   totalBooks,
			TotalReaders: totalReaders,
		}
		total += booksOnLoan
	}
	stats.TotalBooksOnLoan = total
	return stats, nil
}
