package repository

import (
	"database/sql"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
)

type UserRepository struct {
	*BaseRepository
}

func NewUserRepository(config *config.Config) *UserRepository {
	return &UserRepository{
		BaseRepository: NewBaseRepository(config),
	}
}

// GetUserByUsername retrieves user by username from the appropriate site
// Note: User authentication should be handled per site based on role
func (r *UserRepository) GetUserByUsername(username string) (*models.User, error) {
	// Try to authenticate from all sites since we don't know user's site upfront
	for _, site := range r.config.Sites {
		user, err := r.getUserFromSite(username, site.SiteID)
		if err == nil && user != nil {
			return user, nil
		}
	}
	return nil, sql.ErrNoRows
}

func (r *UserRepository) getUserFromSite(username, siteID string) (*models.User, error) {
	conn, err := r.GetConnection(siteID)
	if err != nil {
		return nil, err
	}

	query := `
		SELECT u.Username, u.Role, ISNULL(u.MaCN, '') as MaCN
		FROM (
			SELECT 'ThuThu_Q1' as Username, 'THUTHU' as Role, 'Q1' as MaCN
			UNION ALL
			SELECT 'ThuThu_Q3' as Username, 'THUTHU' as Role, 'Q3' as MaCN  
			UNION ALL
			SELECT 'QuanLy' as Username, 'QUANLY' as Role, '' as MaCN
		) u
		WHERE u.Username = ?
	`

	var user models.User
	err = conn.QueryRow(query, username).Scan(&user.Username, &user.Role, &user.MaCN)
	if err != nil {
		return nil, err
	}

	user.ID = username // Use username as ID for simplicity
	return &user, nil
}

// ValidateCredentials validates user credentials
// For this demo, we use hardcoded passwords matching database_implement.md
func (r *UserRepository) ValidateCredentials(username, password string) bool {
	credentials := map[string]string{
		"ThuThu_Q1": "ThuThu123@",
		"ThuThu_Q3": "ThuThu123@", 
		"QuanLy":    "QuanLy456@",
	}
	
	expectedPassword, exists := credentials[username]
	return exists && expectedPassword == password
}