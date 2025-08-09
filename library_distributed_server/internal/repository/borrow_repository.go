package repository

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
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

// GetBorrowsPaginated gets borrow records with pagination support
func (r *BorrowRepository) GetBorrowsPaginated(siteID string, pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Build queries based on search term
	var baseQuery, countQuery string
	var args []interface{}

	if searchTerm != "" {
		baseQuery = `
			SELECT pm.MaPM, pm.MaDG, pm.MaQuyenSach, pm.MaCN, pm.NgayMuon, pm.NgayTra 
			FROM PHIEUMUON pm 
			JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
			WHERE dg.HoTen LIKE ? OR pm.MaDG LIKE ? OR pm.MaQuyenSach LIKE ?`
		countQuery = `
			SELECT COUNT(*) 
			FROM PHIEUMUON pm 
			JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
			WHERE dg.HoTen LIKE ? OR pm.MaDG LIKE ? OR pm.MaQuyenSach LIKE ?`
		searchPattern := "%" + searchTerm + "%"
		args = []interface{}{searchPattern, searchPattern, searchPattern}
	} else {
		baseQuery = "SELECT MaPM, MaDG, MaQuyenSach, MaCN, NgayMuon, NgayTra FROM PHIEUMUON"
		countQuery = "SELECT COUNT(*) FROM PHIEUMUON"
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

	var borrows []models.PhieuMuon
	for rows.Next() {
		var borrow models.PhieuMuon
		var ngayTra sql.NullTime

		err := rows.Scan(&borrow.MaPM, &borrow.MaDG, &borrow.MaQuyenSach,
			&borrow.MaCN, &borrow.NgayMuon, &ngayTra)
		if err != nil {
			return nil, err
		}

		if ngayTra.Valid {
			borrow.NgayTra = &ngayTra.Time
		}

		borrows = append(borrows, borrow)
	}

	return &PaginatedResult{
		Data:       borrows,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetBorrowRecordsWithDetailsPaginated gets borrow records with details and pagination
func (r *BorrowRepository) GetBorrowRecordsWithDetailsPaginated(siteID string, userRole string, pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Build base query with joins for detailed information
	var baseQuery, countQuery string
	var args []interface{}

	baseSelectClause := `
		SELECT pm.MaPM, s.ISBN, s.TenSach, s.TacGia, 
			   dg.MaDG, dg.HoTen, pm.NgayMuon, pm.NgayTra,
			   pm.MaQuyenSach, pm.MaCN
		FROM PHIEUMUON pm
		JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
		JOIN QUYENSACH qs ON pm.MaQuyenSach = qs.MaQuyenSach
		JOIN SACH s ON qs.ISBN = s.ISBN`

	countSelectClause := `
		SELECT COUNT(*)
		FROM PHIEUMUON pm
		JOIN DOCGIA dg ON pm.MaDG = dg.MaDG
		JOIN QUYENSACH qs ON pm.MaQuyenSach = qs.MaQuyenSach
		JOIN SACH s ON qs.ISBN = s.ISBN`

	if searchTerm != "" {
		whereClause := " WHERE (s.TenSach LIKE ? OR s.TacGia LIKE ? OR dg.HoTen LIKE ? OR pm.MaDG LIKE ?)"
		baseQuery = baseSelectClause + whereClause
		countQuery = countSelectClause + whereClause
		searchPattern := "%" + searchTerm + "%"
		args = []interface{}{searchPattern, searchPattern, searchPattern, searchPattern}
	} else {
		baseQuery = baseSelectClause
		countQuery = countSelectClause
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

	var records []models.BorrowRecordWithDetails
	for rows.Next() {
		var record models.BorrowRecordWithDetails
		var ngayTra sql.NullTime
		var ngayMuon time.Time

		err := rows.Scan(&record.MaPM, &record.BookISBN, &record.BookTitle, &record.BookAuthor,
			&record.ReaderID, &record.ReaderName, &ngayMuon, &ngayTra,
			&record.BookCopyID, &record.Branch)
		if err != nil {
			return nil, err
		}

		// Format dates
		record.BorrowDate = ngayMuon.Format("2006-01-02")

		// Calculate due date (30 days from borrow date)
		dueDate := ngayMuon.AddDate(0, 0, 30)
		record.DueDate = dueDate.Format("2006-01-02")

		if ngayTra.Valid {
			record.ReturnDate = ngayTra.Time.Format("2006-01-02")
			record.Status = "Returned"
			record.DaysOverdue = 0
		} else {
			record.ReturnDate = ""
			now := time.Now()
			if now.After(dueDate) {
				record.Status = "Overdue"
				record.DaysOverdue = int(now.Sub(dueDate).Hours() / 24)
			} else {
				record.Status = "Borrowed"
				record.DaysOverdue = 0
			}
		}

		records = append(records, record)
	}

	return &PaginatedResult{
		Data:       records,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
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

// GetBorrowRecordsWithDetails gets borrow records with detailed information
func (r *BorrowRepository) GetBorrowRecordsWithDetails(siteID string, userRole string) ([]models.BorrowRecordWithDetails, error) {
	var sitesToQuery []string
	if userRole == "QUANLY" {
		sitesToQuery = []string{"Q1", "Q3"}
	} else {
		sitesToQuery = []string{siteID}
	}

	records := make([]models.BorrowRecordWithDetails, 0)

	for _, site := range sitesToQuery {
		siteConn, err := r.GetConnection(site)
		if err != nil {
			continue
		}

		// Query with joins to get detailed information
		query := `
			SELECT 
				pm.SoPhieu, pm.NgayMuon, pm.NgayTra, pm.MaDocGia, pm.SoLuong,
				dg.HoTen, dg.DiaChi, dg.DienThoai,
				qd.QuyenSo, qd.ISBN, qd.TinhTrang,
				s.TenSach, s.TacGia,
				cn.TenCN
			FROM PHIEUMUON pm
			JOIN DOCGIA dg ON pm.MaDocGia = dg.MaDocGia
			LEFT JOIN QUYENMUON qm ON pm.SoPhieu = qm.SoPhieu
			LEFT JOIN QUYENSACH qd ON qm.QuyenSo = qd.QuyenSo
			LEFT JOIN SACH s ON qd.ISBN = s.ISBN
			LEFT JOIN CHINHANH cn ON pm.MaCN = cn.MaCN
			WHERE pm.MaCN = ?
			ORDER BY pm.NgayMuon DESC, pm.SoPhieu
		`

		rows, err := siteConn.Query(query, site)
		if err != nil {
			continue
		}
		defer rows.Close()

		for rows.Next() {
			var record models.BorrowRecordWithDetails
			var ngayTra sql.NullTime
			var quyenSo sql.NullString
			var isbn sql.NullString
			var tinhTrang sql.NullString
			var tenSach sql.NullString
			var tacGia sql.NullString
			var diaChi sql.NullString
			var dienThoai sql.NullString
			var tenCN sql.NullString

			var soPhieu int
			var ngayMuon time.Time
			var maDocGia string
			var soLuong int
			var hoTen string

			err := rows.Scan(
				&soPhieu, &ngayMuon, &ngayTra, &maDocGia, &soLuong,
				&hoTen, &diaChi, &dienThoai,
				&quyenSo, &isbn, &tinhTrang,
				&tenSach, &tacGia,
				&tenCN,
			)
			if err != nil {
				continue
			}

			// Map to DTO structure
			record.MaPM = soPhieu
			record.BookISBN = isbn.String
			record.BookTitle = tenSach.String
			record.BookAuthor = tacGia.String
			record.ReaderID = maDocGia
			record.ReaderName = hoTen
			record.BorrowDate = ngayMuon.Format("2006-01-02")
			record.DueDate = ngayMuon.AddDate(0, 1, 0).Format("2006-01-02") // 1 month due
			record.BookCopyID = quyenSo.String
			record.Branch = site

			if ngayTra.Valid {
				record.ReturnDate = ngayTra.Time.Format("2006-01-02")
				record.Status = "Returned"
				record.DaysOverdue = 0
			} else {
				record.ReturnDate = ""
				dueDate := ngayMuon.AddDate(0, 1, 0)
				if time.Now().After(dueDate) {
					record.Status = "Overdue"
					record.DaysOverdue = int(time.Since(dueDate).Hours() / 24)
				} else {
					record.Status = "Borrowed"
					record.DaysOverdue = 0
				}
			}

			records = append(records, record)
		}
	}

	return records, nil
}
