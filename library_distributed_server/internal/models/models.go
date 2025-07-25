package models

import (
	"time"
)

// ChiNhanh - Fully Replicated table
// @Description Branch information (fully replicated across all sites)
type ChiNhanh struct {
	MaCN   string `json:"maCN" db:"MaCN" example:"Q1" validate:"required"` // Branch code
	TenCN  string `json:"tenCN" db:"TenCN" example:"Thư Viện Quận 1" validate:"required"` // Branch name
	DiaChi string `json:"diaChi" db:"DiaChi" example:"123 Nguyễn Huệ, Q1, TP.HCM"` // Branch address
}

// Sach - Fully Replicated table (Book titles)
// @Description Book information (fully replicated across all sites)
type Sach struct {
	ISBN    string `json:"isbn" db:"ISBN" example:"978-0-123456-78-9" validate:"required"` // Book ISBN
	TenSach string `json:"tenSach" db:"TenSach" example:"Lập trình Go" validate:"required"` // Book title
	TacGia  string `json:"tacGia" db:"TacGia" example:"Nguyễn Văn A"` // Author name
}

// QuyenSach - Horizontally Fragmented by MaCN
// @Description Book copy information (fragmented by branch)
type QuyenSach struct {
	MaQuyenSach string `json:"maQuyenSach" db:"MaQuyenSach" example:"QS001" validate:"required"` // Book copy ID
	ISBN        string `json:"isbn" db:"ISBN" example:"978-0-123456-78-9" validate:"required"` // Book ISBN
	MaCN        string `json:"maCN" db:"MaCN" example:"Q1" validate:"required"` // Branch code
	TinhTrang   string `json:"tinhTrang" db:"TinhTrang" example:"Có sẵn" enums:"Có sẵn,Đang mượn,Bị hỏng"` // Book status
}

// DocGia - Horizontally Fragmented by MaCN_DangKy
// @Description Reader information (fragmented by registration branch)
type DocGia struct {
	MaDG       string `json:"maDG" db:"MaDG" example:"DG001" validate:"required"` // Reader ID
	HoTen      string `json:"hoTen" db:"HoTen" example:"Nguyễn Văn B" validate:"required"` // Reader name
	MaCNDangKy string `json:"maCNDangKy" db:"MaCN_DangKy" example:"Q1" validate:"required"` // Registration branch
}

// PhieuMuon - Horizontally Fragmented by MaCN
// @Description Borrow transaction (fragmented by branch)
type PhieuMuon struct {
	MaPM        int        `json:"maPM" db:"MaPM" example:"1"` // Borrow ID (auto-generated)
	MaDG        string     `json:"maDG" db:"MaDG" example:"DG001" validate:"required"` // Reader ID
	MaQuyenSach string     `json:"maQuyenSach" db:"MaQuyenSach" example:"QS001" validate:"required"` // Book copy ID
	MaCN        string     `json:"maCN" db:"MaCN" example:"Q1" validate:"required"` // Branch code
	NgayMuon    time.Time  `json:"ngayMuon" db:"NgayMuon" example:"2025-01-15T10:00:00Z"` // Borrow date
	NgayTra     *time.Time `json:"ngayTra" db:"NgayTra" example:"2025-01-20T14:00:00Z"` // Return date (null if not returned)
}

// User authentication model
// @Description User account for authentication
type User struct {
	ID       string `json:"id" db:"ID" example:"user123"` // User ID
	Username string `json:"username" db:"Username" example:"thuthu01" validate:"required"` // Username
	Password string `json:"password" db:"Password" example:"password123" validate:"required"` // Password (hashed)
	Role     string `json:"role" db:"Role" example:"THUTHU" enums:"THUTHU,QUANLY"` // User role
	MaCN     string `json:"maCN" db:"MaCN" example:"Q1"` // Branch code (for THUTHU)
}

// BookSearchResult - DTO for book search across all sites
// @Description Book search result with availability across branches
type BookSearchResult struct {
	Sach      Sach       `json:"sach"` // Book information
	ChiNhanh  []ChiNhanh `json:"chiNhanh"` // Available branches
	SoLuongCo int        `json:"soLuongCo" example:"5"` // Total available copies
}

// SystemStats - System-wide statistics
// @Description Distributed system statistics
type SystemStats struct {
	TotalBooksOnLoan int                  `json:"totalBooksOnLoan" example:"150"` // Total books on loan across all sites
	StatsBySite      map[string]SiteStats `json:"statsBySite"` // Statistics by site
}

// SiteStats - Statistics for a specific site
// @Description Site-specific statistics
type SiteStats struct {
	SiteID       string `json:"siteID" example:"Q1"` // Site identifier
	BooksOnLoan  int    `json:"booksOnLoan" example:"75"` // Books currently on loan
	TotalBooks   int    `json:"totalBooks" example:"500"` // Total books in this site
	TotalReaders int    `json:"totalReaders" example:"200"` // Total registered readers
}
