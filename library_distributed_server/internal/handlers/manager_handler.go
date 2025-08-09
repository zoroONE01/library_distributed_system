package handlers

import (
	"fmt"
	"net/http"
	"time"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type ManagerHandler struct {
	bookRepo   *repository.BookRepository
	borrowRepo *repository.BorrowRepository
	readerRepo *repository.ReaderRepository
}

func NewManagerHandler(
	bookRepo *repository.BookRepository,
	borrowRepo *repository.BorrowRepository,
	readerRepo *repository.ReaderRepository,
) *ManagerHandler {
	return &ManagerHandler{
		bookRepo:   bookRepo,
		borrowRepo: borrowRepo,
		readerRepo: readerRepo,
	}
}

// CreateSach handles POST /api/manager/books
// Implements FR10 - CRUD danh mục sách (QuanLy only) with 2PC
// @Summary Create new book (2PC)
// @Description Create a new book in the catalog using 2-Phase Commit (Manager only)
// @Tags Manager
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param book body models.Sach true "Book information"
// @Success 201 {object} models.Sach "Book created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 409 {object} models.ErrorResponse "Book already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /manager/books [post]
func (h *ManagerHandler) CreateSach(c *gin.Context) {
	// Role verification is already done by middleware, proceed with operation

	var sach models.Sach
	if err := c.ShouldBindJSON(&sach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Generate transaction ID for 2PC
	transactionID := fmt.Sprintf("TXN_%d_%s", time.Now().Unix(), sach.ISBN)

	err := h.bookRepo.CreateSach(sach, transactionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create book using 2PC",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, sach)
}

// GetSach handles GET /api/manager/books/{isbn}
// Implements FR10 - Read book information (QuanLy)
// @Summary Get book by ISBN
// @Description Get book information by ISBN (Manager only)
// @Tags Manager
// @Produce json
// @Security BearerAuth
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.Sach "Book found"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /manager/books/{isbn} [get]
func (h *ManagerHandler) GetSach(c *gin.Context) {
	// Role verification is already done by middleware, proceed with operation

	isbn := c.Param("isbn")
	if isbn == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "ISBN parameter is required",
		})
		return
	}

	sach, err := h.bookRepo.ReadSach(isbn, "Q1") // Use any site for replicated data
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Book not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, sach)
}

// SearchAvailableBooks handles GET /api/manager/books/search
// Implements FR7 - Tìm kiếm sách có sẵn toàn hệ thống (QuanLy only)
// @Summary Search available books system-wide
// @Description Search for available books across all sites (Manager only)
// @Tags Manager
// @Produce json
// @Security BearerAuth
// @Param tenSach query string false "Book title search term"
// @Success 200 {object} []models.BookSearchResult "Search results"
// @Failure 400 {object} models.ErrorResponse "Missing search parameters"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /manager/books/search [get]
func (h *ManagerHandler) SearchAvailableBooks(c *gin.Context) {
	// Role verification is already done by middleware, proceed with operation

	tenSach := c.Query("tenSach")
	if tenSach == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Search term 'tenSach' is required",
		})
		return
	}

	results, err := h.bookRepo.SearchAvailableBooks(tenSach)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to search books",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, results)
}

// GetSystemStats handles GET /api/manager/statistics
// Implements FR6 - Thống kê toàn hệ thống (QuanLy only)
// @Summary Get system-wide statistics
// @Description Get comprehensive statistics from all sites in the distributed system (Manager only)
// @Tags Manager
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SystemStats "Statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /manager/statistics [get]
func (h *ManagerHandler) GetSystemStats(c *gin.Context) {
	// Role verification is already done by middleware, proceed with operation

	stats, err := h.borrowRepo.GetSystemStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve system statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetAllReaders handles GET /api/manager/readers
// Implements FR11 - Tra cứu độc giả toàn hệ thống (QuanLy only)
// @Summary Get all readers system-wide
// @Description Get all readers from all sites in the distributed system (Manager only)
// @Tags Manager
// @Produce json
// @Security BearerAuth
// @Param search query string false "Search term for reader name"
// @Success 200 {object} []models.DocGia "Readers retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /manager/readers [get]
func (h *ManagerHandler) GetAllReaders(c *gin.Context) {
	// Role verification is already done by middleware, proceed with operation

	searchTerm := c.Query("search")

	var readers []models.DocGia
	var err error

	if searchTerm != "" {
		readers, err = h.readerRepo.SearchDocGiaSystemWide(searchTerm)
	} else {
		readers, err = h.readerRepo.GetAllDocGiaSystemWide()
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers from system",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, readers)
}
