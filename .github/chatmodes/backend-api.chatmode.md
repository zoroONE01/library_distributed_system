---
description: 'Backend API development mode focusing on Go microservices, MSSQL integration, and distributed service architecture.'
tools: ['codebase', 'editFiles', 'runCommands', 'runTasks', 'runTests', 'search', 'problems', 'git', 'filesystem', 'memory', 'sequential-thinking', 'usages']
---

# Backend API Development Mode

You are in backend API development mode for the distributed library management system. Focus on Go microservices, MSSQL integration, and distributed service architecture.

## Go Backend Architecture

### Project Structure
```
backend/
├── cmd/
│   ├── site-q1/         # Site Q1 service
│   ├── site-q3/         # Site Q3 service
│   └── coordinator/     # Distributed coordinator
├── internal/
│   ├── auth/           # Authentication service
│   ├── repository/     # Data access layer
│   ├── service/        # Business logic
│   ├── handler/        # HTTP handlers
│   ├── middleware/     # HTTP middleware
│   ├── distributed/    # Distributed system logic
│   └── config/         # Configuration management
├── pkg/
│   ├── database/       # Database utilities
│   ├── logger/         # Logging utilities
│   └── errors/         # Error handling
└── api/
    └── openapi/        # API documentation
```

### Core Services Architecture

#### Site Service (Per Branch)
```go
type SiteService struct {
    localDB     *sql.DB
    coordinator *DistributedCoordinator
    logger      *zap.Logger
    config      *Config
}

func (s *SiteService) GetLocalBooks(ctx context.Context, branchID string) ([]Book, error) {
    // Implementation for local book queries
}

func (s *SiteService) BorrowBook(ctx context.Context, req *BorrowRequest) error {
    // Local borrowing with distributed coordination
}
```

#### Distributed Coordinator
```go
type DistributedCoordinator struct {
    sites     map[string]*RemoteSite
    txManager *TwoPhaseCommitManager
    logger    *zap.Logger
}

func (dc *DistributedCoordinator) ExecuteDistributedQuery(ctx context.Context, query *DistributedQuery) (*AggregatedResult, error) {
    // Query distribution and result aggregation
}

func (dc *DistributedCoordinator) BeginDistributedTransaction(ctx context.Context, sites []string) (*DistributedTransaction, error) {
    // Two-phase commit initialization
}
```

## MSSQL Integration on macOS

### Connection Management
```go
// Database configuration for Parallels setup
type DatabaseConfig struct {
    Host     string `env:"DB_HOST" envDefault:"localhost"`
    Port     int    `env:"DB_PORT" envDefault:"1433"`
    Database string `env:"DB_NAME" envDefault:"LibraryDB"`
    Username string `env:"DB_USER"`
    Password string `env:"DB_PASSWORD"`
    
    // Parallels-specific settings
    VMHost        string `env:"VM_HOST" envDefault:"10.211.55.3"`
    MaxRetries    int    `env:"DB_MAX_RETRIES" envDefault:"3"`
    RetryInterval time.Duration `env:"DB_RETRY_INTERVAL" envDefault:"5s"`
}

// Connection pool with retry logic for VM environment
func NewDatabaseConnection(config *DatabaseConfig) (*sql.DB, error) {
    dsn := fmt.Sprintf("server=%s;user id=%s;password=%s;port=%d;database=%s;encrypt=disable",
        config.VMHost, config.Username, config.Password, config.Port, config.Database)
    
    db, err := sql.Open("mssql", dsn)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }
    
    // Configure connection pool for VM environment
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    db.SetConnMaxLifetime(5 * time.Minute)
    
    return db, nil
}
```

### Repository Pattern Implementation
```go
type BookRepository interface {
    GetByID(ctx context.Context, id string) (*Book, error)
    GetByBranch(ctx context.Context, branchID string) ([]Book, error)
    SearchAcrossSystem(ctx context.Context, query string) ([]Book, error)
    UpdateStatus(ctx context.Context, bookID string, status BookStatus) error
}

type MSSQLBookRepository struct {
    db     *sql.DB
    logger *zap.Logger
}

func (r *MSSQLBookRepository) GetByBranch(ctx context.Context, branchID string) ([]Book, error) {
    query := `
        SELECT qs.MaQuyenSach, qs.ISBN, s.TenSach, s.TacGia, qs.TinhTrang
        FROM QUYENSACH qs
        INNER JOIN SACH s ON qs.ISBN = s.ISBN
        WHERE qs.MaCN = ?`
    
    rows, err := r.db.QueryContext(ctx, query, branchID)
    if err != nil {
        return nil, fmt.Errorf("failed to query books: %w", err)
    }
    defer rows.Close()
    
    // Result mapping logic
}
```

## API Design Patterns

### RESTful API Structure
```go
// HTTP handlers with proper error handling
func (h *BookHandler) GetBranchBooks(w http.ResponseWriter, r *http.Request) {
    branchID := mux.Vars(r)["branchId"]
    
    books, err := h.bookService.GetBranchBooks(r.Context(), branchID)
    if err != nil {
        h.logger.Error("failed to get branch books", zap.Error(err))
        http.Error(w, "Internal Server Error", http.StatusInternalServerError)
        return
    }
    
    response := &GetBooksResponse{
        Books:    books,
        BranchID: branchID,
        Count:    len(books),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

// Middleware for authentication and role-based access
func (m *AuthMiddleware) RoleRequired(roles ...string) mux.MiddlewareFunc {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := extractToken(r)
            claims, err := m.validateToken(token)
            if err != nil {
                http.Error(w, "Unauthorized", http.StatusUnauthorized)
                return
            }
            
            if !contains(roles, claims.Role) {
                http.Error(w, "Forbidden", http.StatusForbidden)
                return
            }
            
            ctx := context.WithValue(r.Context(), "userClaims", claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### Distributed Query API
```go
// API endpoint for cross-site queries
func (h *DistributedQueryHandler) SearchBooks(w http.ResponseWriter, r *http.Request) {
    var req SearchBooksRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }
    
    // Route to appropriate handler based on user role
    userClaims := r.Context().Value("userClaims").(*UserClaims)
    
    var results []Book
    var err error
    
    switch userClaims.Role {
    case "THUTHU":
        // Restrict to user's branch only
        results, err = h.bookService.SearchInBranch(r.Context(), req.Query, userClaims.BranchID)
    case "QUANLY":
        // Allow system-wide search
        results, err = h.distributedService.SearchAcrossSystem(r.Context(), req.Query)
    default:
        http.Error(w, "Invalid user role", http.StatusForbidden)
        return
    }
    
    if err != nil {
        h.logger.Error("search failed", zap.Error(err))
        http.Error(w, "Search failed", http.StatusInternalServerError)
        return
    }
    
    response := &SearchBooksResponse{
        Results: results,
        Query:   req.Query,
        Count:   len(results),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
```

## Testing Strategy

### Unit Testing
```go
func TestBookService_GetBranchBooks(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    
    mockRepo := mocks.NewMockBookRepository(ctrl)
    service := NewBookService(mockRepo, zap.NewNop())
    
    expectedBooks := []Book{
        {ID: "B001", ISBN: "123456789", Title: "Test Book"},
    }
    
    mockRepo.EXPECT().
        GetByBranch(gomock.Any(), "Q1").
        Return(expectedBooks, nil)
    
    books, err := service.GetBranchBooks(context.Background(), "Q1")
    
    assert.NoError(t, err)
    assert.Equal(t, expectedBooks, books)
}
```

### Integration Testing
```go
func TestDatabaseIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    db, cleanup := setupTestDatabase(t)
    defer cleanup()
    
    repo := NewMSSQLBookRepository(db, zap.NewNop())
    
    // Test actual database operations
    books, err := repo.GetByBranch(context.Background(), "Q1")
    assert.NoError(t, err)
    assert.NotEmpty(t, books)
}
```

## Deployment and Configuration

### Docker Configuration for Development
```dockerfile
# Dockerfile for site service
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o site-service ./cmd/site-q1

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/site-service .
EXPOSE 8080
CMD ["./site-service"]
```

### Environment Configuration
```go
type Config struct {
    Port        int    `env:"PORT" envDefault:"8080"`
    Environment string `env:"ENVIRONMENT" envDefault:"development"`
    
    Database DatabaseConfig
    Auth     AuthConfig
    
    SiteID      string   `env:"SITE_ID" envDefault:"Q1"`
    RemoteSites []string `env:"REMOTE_SITES" envSeparator:","`
}
```

This mode provides comprehensive guidance for building robust, scalable Go backend services that properly implement distributed database concepts while maintaining clean architecture and testability.