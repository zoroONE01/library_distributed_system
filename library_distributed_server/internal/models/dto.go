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

// BookCopyResponse - Response with book copy information
// @Description Book copy information with book details
type BookCopyResponse struct {
	QuyenSach QuyenSach `json:"quyenSach"` // Book copy information
	Sach      Sach      `json:"sach"`      // Book information
}

// BorrowResponse - Response with borrow information
// @Description Borrow transaction with related information
type BorrowResponse struct {
	PhieuMuon PhieuMuon `json:"phieuMuon"` // Borrow transaction
	DocGia    DocGia    `json:"docGia"`    // Reader information
	Sach      Sach      `json:"sach"`      // Book information
}

// ReaderInfoResponse - Reader information response
// @Description Reader information with borrow history
type ReaderInfoResponse struct {
	DocGia     DocGia      `json:"docGia"`     // Reader information
	PhieuMuons []PhieuMuon `json:"phieuMuons"` // Borrow history
}

// PaginatedResponse - Generic paginated response
// @Description Generic paginated response wrapper
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
