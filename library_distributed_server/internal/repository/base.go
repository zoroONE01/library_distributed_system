package repository

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/pkg/database"
)

type BaseRepository struct {
	config *config.Config
	pool   *database.ConnectionPool
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
