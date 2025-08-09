package repository

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/pkg/database"
	"library_distributed_server/pkg/utils"
)

type BaseRepository struct {
	config *config.Config
	pool   *database.ConnectionPool
}

// PaginatedResult holds paginated query results
type PaginatedResult struct {
	Data       interface{}
	TotalCount int
	Pagination utils.PaginationParams
}

func NewBaseRepository(config *config.Config) *BaseRepository {
	return &BaseRepository{
		config: config,
		pool:   database.GetPool(),
	}
}

func (r *BaseRepository) GetConnection(siteID string) (*sql.DB, error) {
	connectionString := r.config.GetConnectionString(siteID)
	return r.pool.GetConnection(siteID, connectionString)
}

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

func (r *BaseRepository) GetSiteForBranch(maCN string) string {
	for _, site := range r.config.Sites {
		if site.SiteID == maCN {
			return site.SiteID
		}
	}
	return r.config.Sites[0].SiteID
}

// GetTotalCount executes a count query to get total records for pagination
func (r *BaseRepository) GetTotalCount(db *sql.DB, countQuery string, args ...interface{}) (int, error) {
	var count int
	err := db.QueryRow(countQuery, args...).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get total count: %w", err)
	}
	return count, nil
}

// BuildPaginatedQuery adds OFFSET and FETCH clauses to a SQL query
func (r *BaseRepository) BuildPaginatedQuery(baseQuery string, pagination utils.PaginationParams) string {
	offset := pagination.CalculateOffset()
	return fmt.Sprintf("%s ORDER BY 1 OFFSET %d ROWS FETCH NEXT %d ROWS ONLY",
		baseQuery, offset, pagination.Size)
}

// BuildCountQuery converts a SELECT query to a COUNT query
func (r *BaseRepository) BuildCountQuery(selectQuery string) string {
	// Simple approach: wrap the query in a COUNT
	// For more complex queries, might need more sophisticated parsing
	return fmt.Sprintf("SELECT COUNT(*) FROM (%s) AS countable", selectQuery)
}
