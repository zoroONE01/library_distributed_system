package repository

import (
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
)

type ReaderRepository struct {
	*BaseRepository
}

func NewReaderRepository(config *config.Config) *ReaderRepository {
	return &ReaderRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// DocGia Management Methods (FR8) - ThuThu Operations

// CreateDocGia creates a new reader using sp_ThuThu_CreateDocGia
func (r *ReaderRepository) CreateDocGia(docGia models.DocGia) error {
	siteID := r.GetSiteForBranch(docGia.MaCNDangKy)
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_CreateDocGia @MaDG = ?, @HoTen = ?"
	_, err = conn.Exec(query, docGia.MaDG, docGia.HoTen)
	return err
}

// ReadDocGia retrieves reader information using sp_ThuThu_ReadDocGia
func (r *ReaderRepository) ReadDocGia(maDG string, siteID string) (*models.DocGia, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "EXEC sp_ThuThu_ReadDocGia @MaDG = ?"
	row := conn.QueryRow(query, maDG)

	var docGia models.DocGia
	err = row.Scan(&docGia.MaDG, &docGia.HoTen, &docGia.MaCNDangKy)
	if err != nil {
		return nil, err
	}

	return &docGia, nil
}

// UpdateDocGia updates reader information using sp_ThuThu_UpdateDocGia
func (r *ReaderRepository) UpdateDocGia(docGia models.DocGia) error {
	siteID := r.GetSiteForBranch(docGia.MaCNDangKy)
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_UpdateDocGia @MaDG = ?, @HoTen = ?"
	_, err = conn.Exec(query, docGia.MaDG, docGia.HoTen)
	return err
}

// DeleteDocGia deletes a reader using sp_ThuThu_DeleteDocGia
func (r *ReaderRepository) DeleteDocGia(maDG string, siteID string) error {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return err
	}

	query := "EXEC sp_ThuThu_DeleteDocGia @MaDG = ?"
	_, err = conn.Exec(query, maDG)
	return err
}

// GetAllDocGiaLocal retrieves all readers for a specific site (ThuThu access)
func (r *ReaderRepository) GetAllDocGiaLocal(siteID string) ([]models.DocGia, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA WHERE MaCN_DangKy = ? ORDER BY MaDG"
	rows, err := conn.Query(query, siteID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var readers []models.DocGia
	for rows.Next() {
		var reader models.DocGia
		err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
		if err != nil {
			return nil, err
		}
		readers = append(readers, reader)
	}

	return readers, nil
}

// GetAllDocGiaSystemWide retrieves all readers from all sites (QuanLy access - FR11)
func (r *ReaderRepository) GetAllDocGiaSystemWide() ([]models.DocGia, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, err
	}

	var allReaders []models.DocGia

	for siteID, conn := range connections {
		query := "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA ORDER BY MaDG"
		rows, err := conn.Query(query)
		if err != nil {
			return nil, fmt.Errorf("failed to get readers from site %s: %w", siteID, err)
		}

		for rows.Next() {
			var reader models.DocGia
			err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
			if err != nil {
				rows.Close()
				return nil, err
			}
			allReaders = append(allReaders, reader)
		}
		rows.Close()
	}

	return allReaders, nil
}

// SearchDocGiaByName searches for readers by name pattern
func (r *ReaderRepository) SearchDocGiaByName(hoTen string, siteID string) ([]models.DocGia, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA WHERE HoTen LIKE ? AND MaCN_DangKy = ? ORDER BY HoTen"
	rows, err := conn.Query(query, "%"+hoTen+"%", siteID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var readers []models.DocGia
	for rows.Next() {
		var reader models.DocGia
		err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
		if err != nil {
			return nil, err
		}
		readers = append(readers, reader)
	}

	return readers, nil
}

// SearchDocGiaSystemWide searches for readers across all sites (QuanLy access)
func (r *ReaderRepository) SearchDocGiaSystemWide(hoTen string) ([]models.DocGia, error) {
	connections, err := r.GetAllSiteConnections()
	if err != nil {
		return nil, err
	}

	var allReaders []models.DocGia

	for siteID, conn := range connections {
		query := "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA WHERE HoTen LIKE ? ORDER BY HoTen"
		rows, err := conn.Query(query, "%"+hoTen+"%")
		if err != nil {
			return nil, fmt.Errorf("failed to search readers from site %s: %w", siteID, err)
		}

		for rows.Next() {
			var reader models.DocGia
			err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
			if err != nil {
				rows.Close()
				return nil, err
			}
			allReaders = append(allReaders, reader)
		}
		rows.Close()
	}

	return allReaders, nil
}
