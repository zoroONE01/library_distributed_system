package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BorrowHandler struct {
	borrowRepo repository.BorrowRepositoryInterface
	siteID     string
}

func NewBorrowHandler(borrowRepo repository.BorrowRepositoryInterface, siteID string) *BorrowHandler {
	return &BorrowHandler{
		borrowRepo: borrowRepo,
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
// @Param request body models.CreateBorrowRequest true "Borrow request"
// @Success 201 {object} models.SuccessResponse "Borrow created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 500 {object} models.ErrorResponse "Failed to create borrow"
// @Router /borrow [post]
func (h *BorrowHandler) CreateBorrow(c *gin.Context) {
	ctx := c.Request.Context()
	userSite := c.GetString("maCN")

	var req models.CreateBorrowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	// Create PhieuMuon object
	borrow := &models.PhieuMuon{
		MaDG:        req.MaDG,
		MaQuyenSach: req.MaQuyenSach,
		MaCN:        userSite,
	}

	err := h.borrowRepo.CreateBorrow(ctx, borrow, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create borrow transaction",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Borrow transaction created successfully",
		Data:    borrow,
	})
}

// ReturnBook handles PUT /borrow/return/:id
// Implements FR3 - Trả sách (Librarian only, site-specific)
// @Summary Return borrowed book
// @Description Process book return transaction (Librarian only)
// @Tags Borrowing
// @Accept json
// @Produce json
// @Param id path string true "Book copy ID"
// @Param request body models.ReturnBookRequest true "Return request"
// @Success 200 {object} models.SuccessResponse "Book returned successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request"
// @Failure 500 {object} models.ErrorResponse "Failed to return book"
// @Router /borrow/return/{id} [put]
func (h *BorrowHandler) ReturnBook(c *gin.Context) {
	ctx := c.Request.Context()
	maQuyenSach := c.Param("id")
	userSite := c.GetString("maCN")

	err := h.borrowRepo.ReturnBook(ctx, maQuyenSach, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to return book",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book returned successfully",
	})
}

// GetBorrowRecordsWithDetails handles GET /borrow/detailed
// Enhanced for Flutter with comprehensive borrow information
// @Summary Get detailed borrow records
// @Description Get borrow records with book and reader details for Flutter app
// @Tags Borrowing
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of detailed borrow records"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve borrow records"
// @Router /borrow/detailed [get]
func (h *BorrowHandler) GetBorrowRecordsWithDetails(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")
	pagination := utils.ParsePaginationParams(c)

	// Determine which site to query based on user role
	siteID := h.siteID
	if userRole == "THUTHU" {
		siteID = userSite
	}

	records, total, err := h.borrowRepo.GetBorrowRecordsWithDetails(ctx, siteID, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrow records",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(records, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// GetBorrows handles GET /borrow
// @Summary Get borrow transactions
// @Description Retrieve borrow transactions with role-based filtering
// @Tags Borrowing
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of borrow transactions"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve borrows"
// @Router /borrow [get]
func (h *BorrowHandler) GetBorrows(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")
	pagination := utils.ParsePaginationParams(c)

	// Role-based site filtering
	siteID := h.siteID
	if userRole == "THUTHU" {
		siteID = userSite
	}

	borrows, total, err := h.borrowRepo.GetBorrowsBySite(ctx, siteID, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrows",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(borrows, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// GetOverdueBooks handles GET /borrow/overdue
// @Summary Get overdue books
// @Description Get list of overdue books for the site
// @Tags Borrowing
// @Produce json
// @Success 200 {object} models.SuccessResponse "List of overdue books"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve overdue books"
// @Router /borrow/overdue [get]
func (h *BorrowHandler) GetOverdueBooks(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")

	// Determine which site to query
	siteID := h.siteID
	if userRole == "THUTHU" {
		siteID = userSite
	}

	overdueBooks, err := h.borrowRepo.GetOverdueBooks(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve overdue books",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Overdue books retrieved successfully",
		Data:    overdueBooks,
	})
}

// GetBorrowHistory handles GET /borrow/history/:maDG
// @Summary Get borrow history for a reader
// @Description Get borrowing history for a specific reader
// @Tags Borrowing
// @Produce json
// @Param maDG path string true "Reader ID"
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "Reader's borrow history"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve borrow history"
// @Router /borrow/history/{maDG} [get]
func (h *BorrowHandler) GetBorrowHistory(c *gin.Context) {
	ctx := c.Request.Context()
	maDG := c.Param("maDG")
	pagination := utils.ParsePaginationParams(c)

	history, total, err := h.borrowRepo.GetBorrowHistory(ctx, maDG, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrow history",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(history, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// GetBorrowStatistics handles GET /borrow/statistics
// @Summary Get borrowing statistics
// @Description Get borrowing statistics for the site
// @Tags Borrowing
// @Produce json
// @Success 200 {object} models.SuccessResponse "Borrowing statistics"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve statistics"
// @Router /borrow/statistics [get]
func (h *BorrowHandler) GetBorrowStatistics(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")

	// Determine which site to query
	siteID := h.siteID
	if userRole == "THUTHU" {
		siteID = userSite
	}

	stats, err := h.borrowRepo.GetBorrowStatistics(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Statistics retrieved successfully",
		Data:    stats,
	})
}
