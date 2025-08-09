package repository

import (
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/utils"
)

type ReaderRepository struct {
	*BaseRepository
}

func NewReaderRepository(config *config.Config) *ReaderRepository {
	return &ReaderRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// GetAllDocGiaLocalPaginated gets readers from local site with pagination
func (r *ReaderRepository) GetAllDocGiaLocalPaginated(siteID string, pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	// Build queries based on search term
	var baseQuery, countQuery string
	var args []interface{}

	if searchTerm != "" {
		baseQuery = "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA WHERE HoTen LIKE ? OR MaDG LIKE ?"
		countQuery = "SELECT COUNT(*) FROM DOCGIA WHERE HoTen LIKE ? OR MaDG LIKE ?"
		searchPattern := "%" + searchTerm + "%"
		args = []interface{}{searchPattern, searchPattern}
	} else {
		baseQuery = "SELECT MaDG, HoTen, MaCN_DangKy FROM DOCGIA"
		countQuery = "SELECT COUNT(*) FROM DOCGIA"
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

	var readers []models.DocGia
	for rows.Next() {
		var reader models.DocGia
		err := rows.Scan(&reader.MaDG, &reader.HoTen, &reader.MaCNDangKy)
		if err != nil {
			return nil, err
		}
		readers = append(readers, reader)
	}

	return &PaginatedResult{
		Data:       readers,
		TotalCount: totalCount,
		Pagination: pagination,
	}, nil
}

// GetAllDocGiaSystemWidePaginated gets readers from all sites with pagination
func (r *ReaderRepository) GetAllDocGiaSystemWidePaginated(pagination utils.PaginationParams, searchTerm string) (*PaginatedResult, error) {
	connections := map[string]string{"Q1": "Q1", "Q3": "Q3"}
	var allReaders []models.DocGia

	// Collect readers from all sites (in-memory pagination for system-wide queries)
	for siteID := range connections {
		result, err := r.GetAllDocGiaLocalPaginated(siteID, utils.PaginationParams{Page: 0, Size: 10000}, searchTerm)
		if err != nil {
			// Log error but continue with other sites
			continue
		}
		if readers, ok := result.Data.([]models.DocGia); ok {
			allReaders = append(allReaders, readers...)
		}
	}

	totalCount := len(allReaders)

	// Apply pagination to combined results
	start := pagination.CalculateOffset()
	end := start + pagination.Size
	if start >= len(allReaders) {
		allReaders = []models.DocGia{}
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
