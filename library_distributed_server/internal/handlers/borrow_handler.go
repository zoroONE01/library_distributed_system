package handlers

import (
	"net/http"
	"strconv"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BorrowHandler struct {
	borrowRepo *repository.BorrowRepository
	statsRepo  *repository.StatsRepository
	siteID     string
}

func NewBorrowHandler(borrowRepo *repository.BorrowRepository, siteID string) *BorrowHandler {
	return &BorrowHandler{
		borrowRepo: borrowRepo,
		statsRepo:  repository.NewStatsRepository(nil), // Will need proper config
		siteID:     siteID,
	}
}

// CreateBorrow handles POST /borrow
// Implements FR2 - Lập phiếu mượn sách (Librarian only, site-specific)
// @Summary Create borrow transaction
// @Description Create a new book borrowing transaction (Librarian only)
// @Tags Borrowing
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateBorrowRequest true "Borrow request details"
// @Success 201 {object} models.PhieuMuon "Borrow record created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to create borrow record"
// @Router /borrow [post]
func (h *BorrowHandler) CreateBorrow(c *gin.Context) {
	var req models.CreateBorrowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	// Create borrow record using stored procedure
	borrow, err := h.borrowRepo.CreateBorrow(req.MaDG, req.MaQuyenSach, h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create borrow record",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, borrow)
}

// ReturnBook handles PUT /borrow/return/{id}
// Implements FR3 - Ghi nhận trả sách (Librarian only, site-specific)
// @Summary Return borrowed book
// @Description Return a borrowed book and update its status (Librarian only)
// @Tags Borrowing
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "Borrow transaction ID"
// @Param request body models.ReturnBookRequest false "Return details (optional)"
// @Success 204 "Book returned successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid borrow ID format"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to return book"
// @Router /borrow/return/{id} [put]
func (h *BorrowHandler) ReturnBook(c *gin.Context) {
	idParam := c.Param("id")
	maPhieuMuon, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid borrow ID format",
			Details: err.Error(),
		})
		return
	}

	var req models.ReturnBookRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// If no JSON body, just use the ID from URL
		req.MaQuyenSach = ""
	}

	// Return book using stored procedure
	err = h.borrowRepo.ReturnBook(maPhieuMuon, req.MaQuyenSach, h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to return book",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

// GetBorrowRecordsWithDetails handles GET /borrow/detailed
// Enhanced endpoint for Flutter app with detailed borrow information and pagination
// @Summary Get borrow records with details and pagination
// @Description Get borrow records with book and reader details with pagination (enhanced for Flutter app)
// @Tags Borrowing
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Param search query string false "Search term for book title, author, or reader name"
// @Success 200 {object} models.ListResponse "Detailed borrow records retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /borrow/detailed [get]
func (h *BorrowHandler) GetBorrowRecordsWithDetails(c *gin.Context) {
	userRole := c.GetString("role")
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	// Parse pagination parameters
	pagination := utils.ParsePaginationParams(c)
	searchTerm := utils.GetSearchTerm(c)

	result, err := h.borrowRepo.GetBorrowRecordsWithDetailsPaginated(siteID, userRole, pagination, searchTerm)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve detailed borrow records",
			Details: err.Error(),
		})
		return
	}

	// Create Flutter-compatible response
	listResponse := utils.CreateListResponse(result.Data, result.Pagination, result.TotalCount)

	c.JSON(http.StatusOK, listResponse)
}

// GetBorrows handles GET /borrow
// Implements FR4 - Tra cứu cục bộ (Librarian access to local site data) with pagination
// @Summary Get borrow records with pagination
// @Description Get all borrow records for the current site with pagination (Librarian only)
// @Tags Borrowing
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Param search query string false "Search term for reader name or borrow ID"
// @Success 200 {object} models.ListResponse "Borrow records retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve borrow records"
// @Router /borrow [get]
func (h *BorrowHandler) GetBorrows(c *gin.Context) {
	// Parse pagination parameters
	pagination := utils.ParsePaginationParams(c)
	searchTerm := utils.GetSearchTerm(c)

	result, err := h.borrowRepo.GetBorrowsPaginated(h.siteID, pagination, searchTerm)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrow records",
			Details: err.Error(),
		})
		return
	}

	// Create Flutter-compatible response
	listResponse := utils.CreateListResponse(result.Data, result.Pagination, result.TotalCount)

	c.JSON(http.StatusOK, listResponse)
}
