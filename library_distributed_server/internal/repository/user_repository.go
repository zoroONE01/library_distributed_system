package repository

import (
	"database/sql"
	"fmt"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/models"
	"log"
)

type UserRepository struct {
	*BaseRepository
	siteID string // Current site ID for this repository instance
}

func NewUserRepository(config *config.Config, siteID string) *UserRepository {
	return &UserRepository{
		BaseRepository: NewBaseRepository(config),
		siteID:         siteID,
	}
}

// GetUserByUsername retrieves user by username from the current site
func (r *UserRepository) GetUserByUsername(username string) (*models.User, error) {
	conn, err := r.GetConnection(r.siteID)
	if err != nil {
		log.Printf("Failed to get connection for site %s: %v", r.siteID, err)
		return nil, err
	}

	// Use direct query as primary method for now since SP structure is not yet finalized
	user, err := r.tryDirectGetUser(conn, username)
	if err == nil && user != nil {
		log.Printf("Direct getUserInfo successful for user: %s", username)
		return user, nil
	}

	log.Printf("Direct getUserInfo failed for user %s: %v, trying SP", username, err)

	// Fallback to SP
	return r.tryStoredProcedureGetUser(conn, username)
}

// tryStoredProcedureGetUser tries getting user info using stored procedure
func (r *UserRepository) tryStoredProcedureGetUser(conn *sql.DB, username string) (*models.User, error) {
	// Use sp_Login to get user info (it contains role and branch info)
	query := "EXEC sp_Login @Username = ?, @Password = ?"

	// For getting user info, we'll use a dummy password and check if user exists
	// In practice, this should be a separate sp_GetUserInfo SP
	var loginStatus, message, returnedUsername, hoTen, role, chiNhanh, serverName sql.NullString

	err := conn.QueryRow(query, username, "dummy_password_for_info").Scan(
		&loginStatus,
		&message,
		&returnedUsername,
		&hoTen,
		&role,
		&chiNhanh,
		&serverName,
	)

	if err != nil {
		log.Printf("SP sp_Login (for user info) error for user %s: %v", username, err)
		return nil, err
	}

	log.Printf("SP sp_Login (for user info) result for user %s: Status=%s, Role=%s, ChiNhanh=%s",
		username, loginStatus.String, role.String, chiNhanh.String)

	// Even if login failed due to password, we can still extract user role info
	if returnedUsername.Valid && role.Valid {
		user := &models.User{
			ID:       username,
			Username: username,
			Role:     role.String,
		}

		if chiNhanh.Valid {
			user.MaCN = chiNhanh.String
		} else {
			user.MaCN = "" // For QuanLy role
		}

		return user, nil
	}

	return nil, fmt.Errorf("user not found or invalid: %s", username)
}

// tryDirectGetUser tries getting user info using direct query as fallback
func (r *UserRepository) tryDirectGetUser(conn *sql.DB, username string) (*models.User, error) {
	query := `
		SELECT 
			dp.name as Username,
			CASE 
				WHEN dp.name LIKE 'ThuThu_%' THEN 'THUTHU'
				WHEN dp.name = 'QuanLy' THEN 'QUANLY'
				ELSE 'UNKNOWN'
			END as Role,
			CASE 
				WHEN dp.name = 'ThuThu_Q1' THEN 'Q1'
				WHEN dp.name = 'ThuThu_Q3' THEN 'Q3'
				WHEN dp.name = 'QuanLy' THEN ''
				ELSE ''
			END as MaCN
		FROM sys.database_principals dp
		WHERE dp.type = 'S' 
			AND dp.name IN ('ThuThu_Q1', 'ThuThu_Q3', 'QuanLy')
			AND dp.name = ?
	`

	var user models.User
	err := conn.QueryRow(query, username).Scan(&user.Username, &user.Role, &user.MaCN)
	if err != nil {
		return nil, err
	}

	user.ID = username
	return &user, nil
}

// ValidateCredentials validates user credentials using direct SQL Server authentication
func (r *UserRepository) ValidateCredentials(username, password string) bool {
	// Use direct SQL Server authentication as primary method for now
	// since SP structure is not yet finalized
	if r.tryDirectAuth(username, password) {
		log.Printf("Direct auth successful for user: %s", username)
		return true
	}

	// Fallback to SP if direct auth fails
	conn, err := r.GetConnection(r.siteID)
	if err != nil {
		log.Printf("Failed to get connection for site %s: %v", r.siteID, err)
		return false
	}

	log.Printf("Direct auth failed, trying SP for user: %s", username)
	return r.tryStoredProcedureAuth(conn, username, password)
}

// tryStoredProcedureAuth tries authentication using stored procedure
func (r *UserRepository) tryStoredProcedureAuth(conn *sql.DB, username, password string) bool {
	query := "EXEC sp_Login @Username = ?, @Password = ?"

	var loginStatus, message, returnedUsername, hoTen, role, chiNhanh, serverName sql.NullString

	err := conn.QueryRow(query, username, password).Scan(
		&loginStatus,
		&message,
		&returnedUsername,
		&hoTen,
		&role,
		&chiNhanh,
		&serverName,
	)

	if err != nil {
		log.Printf("SP sp_Login scan error for user %s: %v", username, err)
		return false
	}

	log.Printf("SP sp_Login result for user %s: Status=%s, Message=%s, Role=%s, ChiNhanh=%s",
		username, loginStatus.String, message.String, role.String, chiNhanh.String)

	// Check if login was successful
	return loginStatus.Valid && loginStatus.String == "SUCCESS"
}

// tryDirectAuth tries direct SQL Server authentication as fallback
func (r *UserRepository) tryDirectAuth(username, password string) bool {
	// Get site config
	var siteConfig *config.SiteConfig
	for _, site := range r.config.Sites {
		if site.SiteID == r.siteID {
			siteConfig = &site
			break
		}
	}

	if siteConfig == nil {
		log.Printf("Site config not found for site: %s", r.siteID)
		return false
	}

	// Build connection string with user credentials
	connStr := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;database=%s;encrypt=disable;trustServerCertificate=true",
		siteConfig.Host, username, password, siteConfig.Port, siteConfig.Database)

	// Try to connect with the provided credentials
	db, err := sql.Open("sqlserver", connStr)
	if err != nil {
		log.Printf("Failed to open connection for user %s: %v", username, err)
		return false
	}
	defer db.Close()

	// Test the connection
	err = db.Ping()
	if err != nil {
		log.Printf("Failed to ping with user %s credentials: %v", username, err)
		return false
	}

	log.Printf("Direct auth successful for user: %s", username)
	return true
}

// GetCurrentUserInfo gets detailed user information using sp_Login
func (r *UserRepository) GetCurrentUserInfo(username string) (*models.UserInfo, error) {
	conn, err := r.GetConnection(r.siteID)
	if err != nil {
		return nil, err
	}

	// Use sp_Login to get detailed user information
	query := "EXEC sp_Login @Username = ?, @Password = ?"

	var userInfo models.UserInfo
	var loginStatus, message, returnedUsername, hoTen, role, chiNhanh, serverName sql.NullString

	// Use dummy password for info retrieval (in practice, this should be a separate SP)
	err = conn.QueryRow(query, username, "dummy_password_for_info").Scan(
		&loginStatus,
		&message,
		&returnedUsername,
		&hoTen,
		&role,
		&chiNhanh,
		&serverName,
	)
	if err != nil {
		return nil, err
	}

	// Populate user info from SP results
	userInfo.ID = username
	userInfo.Username = username

	if role.Valid {
		userInfo.Role = role.String
	}

	if chiNhanh.Valid {
		userInfo.MaCN = chiNhanh.String
	} else {
		userInfo.MaCN = "" // For QuanLy role
	}

	// Set permissions based on role
	if role.Valid {
		switch role.String {
		case "THUTHU":
			userInfo.Permissions = "BRANCH_ACCESS,BOOK_BORROW,BOOK_RETURN"
		case "QUANLY":
			userInfo.Permissions = "SYSTEM_ACCESS,ALL_BRANCHES,STATISTICS,REPORTS"
		default:
			userInfo.Permissions = ""
		}
	}

	return &userInfo, nil
}
