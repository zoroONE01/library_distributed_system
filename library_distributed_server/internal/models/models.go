package models

import (
	"time"
)

// ChiNhanh - Fully Replicated table
type ChiNhanh struct {
	MaCN   string `json:"maCN" db:"MaCN"`
	TenCN  string `json:"tenCN" db:"TenCN"`
	DiaChi string `json:"diaChi" db:"DiaChi"`
}

// Sach - Fully Replicated table (Book titles)
type Sach struct {
	ISBN    string `json:"isbn" db:"ISBN"`
	TenSach string `json:"tenSach" db:"TenSach"`
	TacGia  string `json:"tacGia" db:"TacGia"`
}

// QuyenSach - Horizontally Fragmented by MaCN
type QuyenSach struct {
	MaQuyenSach string `json:"maQuyenSach" db:"MaQuyenSach"`
	ISBN        string `json:"isbn" db:"ISBN"`
	MaCN        string `json:"maCN" db:"MaCN"`
	TinhTrang   string `json:"tinhTrang" db:"TinhTrang"`
}

// DocGia - Horizontally Fragmented by MaCN_DangKy
type DocGia struct {
	MaDG       string `json:"maDG" db:"MaDG"`
	HoTen      string `json:"hoTen" db:"HoTen"`
	MaCNDangKy string `json:"maCNDangKy" db:"MaCN_DangKy"`
}

// PhieuMuon - Horizontally Fragmented by MaCN
type PhieuMuon struct {
	MaPM        int        `json:"maPM" db:"MaPM"`
	MaDG        string     `json:"maDG" db:"MaDG"`
	MaQuyenSach string     `json:"maQuyenSach" db:"MaQuyenSach"`
	MaCN        string     `json:"maCN" db:"MaCN"`
	NgayMuon    time.Time  `json:"ngayMuon" db:"NgayMuon"`
	NgayTra     *time.Time `json:"ngayTra" db:"NgayTra"`
}

// User authentication model
type User struct {
	ID       string `json:"id" db:"ID"`
	Username string `json:"username" db:"Username"`
	Password string `json:"password" db:"Password"`
	Role     string `json:"role" db:"Role"` // THUTHU, QUANLY
	MaCN     string `json:"maCN" db:"MaCN"` // For THUTHU, specifies branch
}

// DTO for book search across all sites
type BookSearchResult struct {
	Sach      Sach       `json:"sach"`
	ChiNhanh  []ChiNhanh `json:"chiNhanh"`
	SoLuongCo int        `json:"soLuongCo"`
}

type SystemStats struct {
	TotalBooksOnLoan int                  `json:"totalBooksOnLoan"`
	StatsBySite      map[string]SiteStats `json:"statsBySite"`
}

type SiteStats struct {
	SiteID       string `json:"siteID"`
	BooksOnLoan  int    `json:"booksOnLoan"`
	TotalBooks   int    `json:"totalBooks"`
	TotalReaders int    `json:"totalReaders"`
}
