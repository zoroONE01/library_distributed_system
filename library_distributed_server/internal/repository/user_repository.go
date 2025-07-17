package repository

import (
    "context"
    "database/sql"
    "errors"
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

func (r *UserRepository) GetUserByUsername(ctx context.Context, username string) (models.User, error) {
    // For demo, query from first site (can be improved for distributed user management)
    conn, err := r.GetConnection(r.config.Sites[0].SiteID)
    if err != nil {
        return models.User{}, err
    }
    query := "SELECT ID, Username, Password, Role, MaCN FROM USERS WHERE Username = ?"
    row := conn.QueryRowContext(ctx, query, username)
    var user models.User
    err = row.Scan(&user.ID, &user.Username, &user.Password, &user.Role, &user.MaCN)
    if err == sql.ErrNoRows {
        return models.User{}, errors.New("user not found")
    }
    if err != nil {
        return models.User{}, err
    }
    return user, nil
}
