package models

import "time"

// Request DTOs

// CreateBorrowRequest - Request to create a new borrow transaction
// @Description Request payload for creating a borrow transaction
type CreateBorrowRequest struct {
	MaDG        string `json:"maDG" binding:"required" example:"DG001" validate:"required"`        // Reader ID
	MaQuyenSach string `json:"maQuyenSach" binding:"required" example:"QS001" validate:"required"` // Book copy ID
}

// ReturnBookRequest - Request to return a borrowed book
// @Description Request payload for returning a borrowed book
type ReturnBookRequest struct {
	MaQuyenSach string    `json:"maQuyenSach" example:"QS001"`            // Book copy ID (optional)
	NgayTra     time.Time `json:"ngayTra" example:"2025-01-20T14:00:00Z"` // Return date
}

// SearchBooksRequest - Request for searching books across sites
// @Description Request payload for searching books across all sites
type SearchBooksRequest struct {
	Query string `json:"query" form:"query" example:"Go programming" validate:"required"` // Search query
	ISBN  string `json:"isbn" form:"isbn" example:"978-0-123456-78-9"`                    // ISBN filter (optional)
}

// TransferBookRequest - Request for transferring book between sites
// @Description Request payload for transferring a book copy between sites using 2PC protocol
type TransferBookRequest struct {
	MaQuyenSach string `json:"maQuyenSach" binding:"required" example:"QS001" validate:"required"` // Book copy ID to transfer
	FromSite    string `json:"fromSite" binding:"required" example:"Q1" validate:"required"`       // Source site ID
	ToSite      string `json:"toSite" binding:"required" example:"Q3" validate:"required"`         // Destination site ID
}

// Response DTOs

// SuccessResponse - Generic success response
// @Description Generic success response
type SuccessResponse struct {
	Success bool        `json:"success" example:"true"`                             // Operation success status
	Message string      `json:"message" example:"Operation completed successfully"` // Success message
	Data    interface{} `json:"data,omitempty"`                                     // Response data (optional)
}

// ErrorResponse - Generic error response
// @Description Generic error response
type ErrorResponse struct {
	Error   string      `json:"error" example:"Bad Request"` // Error message
	Details interface{} `json:"details,omitempty"`           // Error details (optional)
}

// HealthResponse - Health check response
// @Description Health check response
type HealthResponse struct {
	Status    string    `json:"status" example:"healthy"`                     // Service status
	Site      string    `json:"site" example:"Q1"`                            // Site identifier
	Time      time.Time `json:"time" example:"2025-01-15T10:00:00Z"`          // Current time
	Service   string    `json:"service,omitempty" example:"Site Q1 API"`      // Service name (optional)
	Protocols []string  `json:"protocols,omitempty" example:"HTTP,HTTPS,2PC"` // Supported protocols (optional)
}

// BookWithAvailability - Book information with availability count
// @Description Book information combined with availability count for client applications
type BookWithAvailability struct {
	ISBN           string `json:"isbn" example:"978-0-123456-78-9"` // Book ISBN (ID)
	TenSach        string `json:"tenSach" example:"Lập trình Go"`   // Book title
	TacGia         string `json:"tacGia" example:"Nguyễn Văn A"`    // Author name
	AvailableCount int    `json:"availableCount" example:"5"`       // Available copies count
	TotalCount     int    `json:"totalCount" example:"10"`          // Total copies count
	BorrowedCount  int    `json:"borrowedCount" example:"5"`        // Currently borrowed count
}

// BorrowRecordWithDetails - Complete borrow record with all related information
// @Description Borrow record with book and reader details for easy display
type BorrowRecordWithDetails struct {
	MaPM        int    `json:"maPM" example:"1"`                     // Borrow record ID
	BookISBN    string `json:"bookIsbn" example:"978-0-123456-78-9"` // Book ISBN
	BookTitle   string `json:"bookTitle" example:"Lập trình Go"`     // Book title
	BookAuthor  string `json:"bookAuthor" example:"Nguyễn Văn A"`    // Book author
	ReaderID    string `json:"readerId" example:"DG001"`             // Reader ID
	ReaderName  string `json:"readerName" example:"Nguyễn Văn B"`    // Reader name
	BorrowDate  string `json:"borrowDate" example:"2025-01-15"`      // Borrow date
	DueDate     string `json:"dueDate" example:"2025-02-15"`         // Due date (calculated)
	ReturnDate  string `json:"returnDate" example:"2025-01-20"`      // Return date (empty if not returned)
	Status      string `json:"status" example:"Borrowed"`            // Status: "Borrowed", "Returned", "Overdue"
	DaysOverdue int    `json:"daysOverdue" example:"0"`              // Days overdue (0 if not overdue)
	BookCopyID  string `json:"bookCopyId" example:"QS001"`           // Book copy ID for operations
	Branch      string `json:"branch" example:"Q1"`                  // Branch where transaction occurred
}

// ReaderWithStats - Reader information with borrowing statistics
// @Description Reader information with borrowing statistics for better insights
type ReaderWithStats struct {
	MaDG            string `json:"maDG" example:"DG001"`                // Reader ID
	HoTen           string `json:"hoTen" example:"Nguyễn Văn B"`        // Reader name
	MaCNDangKy      string `json:"maCNDangKy" example:"Q1"`             // Registration branch
	TotalBorrowed   int    `json:"totalBorrowed" example:"25"`          // Total books borrowed
	CurrentBorrowed int    `json:"currentBorrowed" example:"3"`         // Currently borrowed books
	OverdueBooks    int    `json:"overdueBooks" example:"1"`            // Overdue books count
	LastBorrowDate  string `json:"lastBorrowDate" example:"2025-01-15"` // Last borrow date
}

// SystemStatsResponse - System-wide statistics for managers
// @Description Comprehensive system statistics across all sites
type SystemStatsResponse struct {
	TotalBooks    int                    `json:"totalBooks" example:"1000"`                  // Total books in catalog
	TotalCopies   int                    `json:"totalCopies" example:"5000"`                 // Total book copies
	TotalReaders  int                    `json:"totalReaders" example:"2000"`                // Total registered readers
	ActiveBorrows int                    `json:"activeBorrows" example:"500"`                // Currently borrowed books
	OverdueBooks  int                    `json:"overdueBooks" example:"50"`                  // Overdue books
	SiteStats     []SiteStats            `json:"siteStats"`                                  // Per-site statistics
	PopularBooks  []BookWithAvailability `json:"popularBooks"`                               // Most borrowed books
	GeneratedAt   string                 `json:"generatedAt" example:"2025-01-15T10:00:00Z"` // Stats generation time
}

// PagingInfo - Pagination information compatible with Flutter PagingModel
// @Description Pagination information matching Flutter PagingModel structure
type PagingInfo struct {
	Page       int `json:"page" example:"0"`        // Current page number (0-based, matches Flutter)
	Size       int `json:"size" example:"20"`       // Items per page (matches Flutter)
	TotalPages int `json:"totalPages" example:"10"` // Total number of pages (matches Flutter)
}

// ListResponse - Generic list response with pagination compatible with Flutter BookListModel
// @Description Generic paginated list response matching Flutter BookListModel structure
type ListResponse struct {
	Items  interface{} `json:"items"`  // List of items (matches Flutter items field)
	Paging PagingInfo  `json:"paging"` // Pagination info (matches Flutter paging field)
}

// PaginatedResponse - Generic paginated response (deprecated, use ListResponse instead)
// @Description Generic paginated response wrapper (deprecated)
type PaginatedResponse struct {
	Data       interface{} `json:"data"`                     // Response data
	TotalCount int         `json:"totalCount" example:"100"` // Total number of items
	Page       int         `json:"page" example:"1"`         // Current page number
	PageSize   int         `json:"pageSize" example:"10"`    // Items per page
	TotalPages int         `json:"totalPages" example:"10"`  // Total number of pages
}

// TransferBookResponse - Response for book transfer operation
// @Description Response after successful book transfer using 2PC protocol
type TransferBookResponse struct {
	Message     string `json:"message" example:"Book transferred successfully using 2PC protocol"` // Success message
	MaQuyenSach string `json:"maQuyenSach" example:"QS001"`                                        // Transferred book copy ID
	FromSite    string `json:"fromSite" example:"Q1"`                                              // Source site ID
	ToSite      string `json:"toSite" example:"Q3"`                                                // Destination site ID
	Protocol    string `json:"protocol" example:"Two-Phase Commit (2PC)"`                          // Protocol used
	Coordinator string `json:"coordinator" example:"Distributed Transaction Coordinator"`          // Coordinator service
}
