package repository

import (
	"context"
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"library_distributed_server/pkg/database"
	"library_distributed_server/pkg/utils"
	"log"
	"strings"
)

// BaseRepository provides common raw SQL operations for all repositories
type BaseRepository struct {
	config *config.Config
	pool   *database.ConnectionPool
}

// QueryResult represents a generic query result
type QueryResult struct {
	Data       interface{}
	TotalCount int
	Error      error
}

// ValidationRule defines business rule validation
type ValidationRule interface {
	Validate(ctx context.Context, data map[string]interface{}) error
}

// FragmentationConstraint enforces fragmentation rules
type FragmentationConstraint struct {
	Table        string
	FragmentKey  string
	ExpectedSite string
}

func (fc FragmentationConstraint) Validate(ctx context.Context, data map[string]interface{}) error {
	if value, exists := data[fc.FragmentKey]; exists {
		if value != fc.ExpectedSite {
			return fmt.Errorf("fragmentation violation: %s.%s=%v must be %s for this site",
				fc.Table, fc.FragmentKey, value, fc.ExpectedSite)
		}
	}
	return nil
}

// NewBaseRepository creates a new base repository with raw SQL capabilities
func NewBaseRepository(config *config.Config) *BaseRepository {
	pool := database.GetPool()
	return &BaseRepository{
		config: config,
		pool:   pool,
	}
}

// GetConnection returns a database connection for the specified site
func (r *BaseRepository) GetConnection(siteID string) (*sql.DB, error) {
	connectionString := r.config.GetConnectionString(siteID)
	return r.pool.GetConnection(siteID, connectionString)
}

// GetAllSiteConnections returns connections to all configured sites
func (r *BaseRepository) GetAllSiteConnections() (map[string]*sql.DB, error) {
	connections := make(map[string]*sql.DB)
	for _, site := range r.config.Sites {
		conn, err := r.GetConnection(site.SiteID)
		if err != nil {
			return nil, fmt.Errorf("failed to connect to site %s: %w", site.SiteID, err)
		}
		connections[site.SiteID] = conn
	}
	return connections, nil
}

// ValidateFragmentation validates fragmentation constraints before operations
func (r *BaseRepository) ValidateFragmentation(ctx context.Context, table string, data map[string]interface{}, siteID string) error {
	switch table {
	case "DOCGIA":
		constraint := FragmentationConstraint{
			Table:        "DOCGIA",
			FragmentKey:  "MaCN_DangKy",
			ExpectedSite: siteID,
		}
		return constraint.Validate(ctx, data)
	case "QUYENSACH":
		constraint := FragmentationConstraint{
			Table:        "QUYENSACH",
			FragmentKey:  "MaCN",
			ExpectedSite: siteID,
		}
		return constraint.Validate(ctx, data)
	case "PHIEUMUON":
		constraint := FragmentationConstraint{
			Table:        "PHIEUMUON",
			FragmentKey:  "MaCN",
			ExpectedSite: siteID,
		}
		return constraint.Validate(ctx, data)
	}
	return nil
}

// ExecuteWithTransaction executes a function within a database transaction
func (r *BaseRepository) ExecuteWithTransaction(ctx context.Context, db *sql.DB, fn func(*sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{
		Isolation: sql.LevelSerializable, // Strong consistency
	})
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	if err := fn(tx); err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// ExecuteQuery executes a SELECT query with optional pagination
func (r *BaseRepository) ExecuteQuery(ctx context.Context, db *sql.DB, query string, args []interface{}, pagination *utils.PaginationParams) (*sql.Rows, error) {
	finalQuery := query
	finalArgs := args

	if pagination != nil {
		offset := pagination.CalculateOffset()
		finalQuery = fmt.Sprintf("%s ORDER BY 1 OFFSET %d ROWS FETCH NEXT %d ROWS ONLY",
			query, offset, pagination.Size)
	}

	log.Printf("Executing query: %s with args: %v", finalQuery, finalArgs)

	rows, err := db.QueryContext(ctx, finalQuery, finalArgs...)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}

	return rows, nil
}

// GetTotalCount executes a count query for pagination
func (r *BaseRepository) GetTotalCount(ctx context.Context, db *sql.DB, countQuery string, args []interface{}) (int, error) {
	var count int
	err := db.QueryRowContext(ctx, countQuery, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get total count: %w", err)
	}
	return count, nil
}

// ExecuteParallelQueries executes queries on multiple sites in parallel
func (r *BaseRepository) ExecuteParallelQueries(ctx context.Context, queries map[string]string, args map[string][]interface{}) map[string]QueryResult {
	results := make(map[string]QueryResult)
	resultChan := make(chan struct {
		site   string
		result QueryResult
	}, len(queries))

	// Execute queries in parallel
	for siteID, query := range queries {
		go func(site string, q string) {
			db, err := r.GetConnection(site)
			if err != nil {
				resultChan <- struct {
					site   string
					result QueryResult
				}{site, QueryResult{Error: err}}
				return
			}

			queryArgs := args[site]
			rows, err := r.ExecuteQuery(ctx, db, q, queryArgs, nil)
			if err != nil {
				resultChan <- struct {
					site   string
					result QueryResult
				}{site, QueryResult{Error: err}}
				return
			}
			defer rows.Close()

			// For now, just return the rows - specific repositories will handle scanning
			resultChan <- struct {
				site   string
				result QueryResult
			}{site, QueryResult{Data: rows, Error: nil}}
		}(siteID, query)
	}

	// Collect results
	for i := 0; i < len(queries); i++ {
		result := <-resultChan
		results[result.site] = result.result
	}

	return results
}

// CheckRecordExists checks if a record exists with given conditions
func (r *BaseRepository) CheckRecordExists(ctx context.Context, db *sql.DB, table string, conditions map[string]interface{}) (bool, error) {
	var whereClause []string
	var args []interface{}

	for column, value := range conditions {
		whereClause = append(whereClause, fmt.Sprintf("%s = ?", column))
		args = append(args, value)
	}

	query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE %s", table, strings.Join(whereClause, " AND "))

	var count int
	err := db.QueryRowContext(ctx, query, args...).Scan(&count)
	if err != nil {
		return false, fmt.Errorf("failed to check record existence: %w", err)
	}

	return count > 0, nil
}

// GetCurrentSiteFromUserContext extracts site information from user context
func (r *BaseRepository) GetCurrentSiteFromUserContext(ctx context.Context) string {
	// This would typically extract from JWT claims in context
	// For now, we'll use a simple approach
	if siteID := ctx.Value("siteID"); siteID != nil {
		return siteID.(string)
	}
	return ""
}

// BuildInsertQuery builds a parameterized INSERT query
func (r *BaseRepository) BuildInsertQuery(table string, data map[string]interface{}) (string, []interface{}) {
	var columns []string
	var placeholders []string
	var args []interface{}

	for column, value := range data {
		columns = append(columns, column)
		placeholders = append(placeholders, "?")
		args = append(args, value)
	}

	query := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s)",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "))

	return query, args
}

// BuildUpdateQuery builds a parameterized UPDATE query
func (r *BaseRepository) BuildUpdateQuery(table string, data map[string]interface{}, conditions map[string]interface{}) (string, []interface{}) {
	var setClauses []string
	var whereClause []string
	var args []interface{}

	// Build SET clause
	for column, value := range data {
		setClauses = append(setClauses, fmt.Sprintf("%s = ?", column))
		args = append(args, value)
	}

	// Build WHERE clause
	for column, value := range conditions {
		whereClause = append(whereClause, fmt.Sprintf("%s = ?", column))
		args = append(args, value)
	}

	query := fmt.Sprintf("UPDATE %s SET %s WHERE %s",
		table,
		strings.Join(setClauses, ", "),
		strings.Join(whereClause, " AND "))

	return query, args
}

// BuildDeleteQuery builds a parameterized DELETE query
func (r *BaseRepository) BuildDeleteQuery(table string, conditions map[string]interface{}) (string, []interface{}) {
	var whereClause []string
	var args []interface{}

	for column, value := range conditions {
		whereClause = append(whereClause, fmt.Sprintf("%s = ?", column))
		args = append(args, value)
	}

	query := fmt.Sprintf("DELETE FROM %s WHERE %s",
		table,
		strings.Join(whereClause, " AND "))

	return query, args
}

// ScanDocGia scans a row into DocGia model
func (r *BaseRepository) ScanDocGia(rows *sql.Rows) (*models.DocGia, error) {
	var docGia models.DocGia
	err := rows.Scan(&docGia.MaDG, &docGia.HoTen, &docGia.MaCNDangKy)
	if err != nil {
		return nil, fmt.Errorf("failed to scan DocGia: %w", err)
	}
	return &docGia, nil
}

// ScanQuyenSach scans a row into QuyenSach model
func (r *BaseRepository) ScanQuyenSach(rows *sql.Rows) (*models.QuyenSach, error) {
	var quyenSach models.QuyenSach
	err := rows.Scan(&quyenSach.MaQuyenSach, &quyenSach.ISBN, &quyenSach.MaCN, &quyenSach.TinhTrang)
	if err != nil {
		return nil, fmt.Errorf("failed to scan QuyenSach: %w", err)
	}
	return &quyenSach, nil
}

// ScanPhieuMuon scans a row into PhieuMuon model
func (r *BaseRepository) ScanPhieuMuon(rows *sql.Rows) (*models.PhieuMuon, error) {
	var phieuMuon models.PhieuMuon
	err := rows.Scan(&phieuMuon.MaPM, &phieuMuon.MaDG, &phieuMuon.MaQuyenSach,
		&phieuMuon.MaCN, &phieuMuon.NgayMuon, &phieuMuon.NgayTra)
	if err != nil {
		return nil, fmt.Errorf("failed to scan PhieuMuon: %w", err)
	}
	return &phieuMuon, nil
}

// ScanSach scans a row into Sach model
func (r *BaseRepository) ScanSach(rows *sql.Rows) (*models.Sach, error) {
	var sach models.Sach
	err := rows.Scan(&sach.ISBN, &sach.TenSach, &sach.TacGia)
	if err != nil {
		return nil, fmt.Errorf("failed to scan Sach: %w", err)
	}
	return &sach, nil
}

// ScanChiNhanh scans a row into ChiNhanh model
func (r *BaseRepository) ScanChiNhanh(rows *sql.Rows) (*models.ChiNhanh, error) {
	var chiNhanh models.ChiNhanh
	err := rows.Scan(&chiNhanh.MaCN, &chiNhanh.TenCN, &chiNhanh.DiaChi)
	if err != nil {
		return nil, fmt.Errorf("failed to scan ChiNhanh: %w", err)
	}
	return &chiNhanh, nil
}

// LogQuery logs SQL queries for debugging (development only)
func (r *BaseRepository) LogQuery(query string, args []interface{}) {
	log.Printf("SQL: %s | Args: %v", query, args)
}

// GetSiteIDFromContext extracts site ID from request context
func (r *BaseRepository) GetSiteIDFromContext(ctx context.Context) string {
	if siteID := ctx.Value("siteID"); siteID != nil {
		return siteID.(string)
	}
	// Default to first configured site if not specified
	if len(r.config.Sites) > 0 {
		return r.config.Sites[0].SiteID
	}
	return "Q1"
}
