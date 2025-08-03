package handlers

import (
	"net/http"
	"strconv"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type BorrowHandler struct {
	borrowRepo *repository.BorrowRepository
	siteID     string
}

func NewBorrowHandler(borrowRepo *repository.BorrowRepository, siteID string) *BorrowHandler {
	return &BorrowHandler{
		borrowRepo: borrowRepo,
		siteID:     siteID,
	}
}

// CreateBorrow handles POST /api/site/{siteID}/borrow
// Implements FR2 - Lập phiếu mượn sách (Librarian only, site-specific)
// @Summary Create borrow transaction
// @Description Create a new book borrowing transaction (Librarian only)
// @Tags Borrowing
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateBorrowRequest true "Borrow request details"
// @Success 201 {object} models.SuccessResponse{data=models.BorrowResponse} "Borrow record created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to create borrow record"
// @Router /api/site/{siteID}/borrow [post]
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

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Borrow record created successfully",
		Data: gin.H{
			"borrow": borrow,
			"site":   h.siteID,
		},
	})
}

// ReturnBook handles PUT /api/site/{siteID}/return/{id}
// Implements FR3 - Ghi nhận trả sách (Librarian only, site-specific)
// @Summary Return borrowed book
// @Description Return a borrowed book and update its status (Librarian only)
// @Tags Borrowing
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "Borrow transaction ID"
// @Param request body models.ReturnBookRequest false "Return details (optional)"
// @Success 200 {object} models.SuccessResponse "Book returned successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid borrow ID format"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to return book"
// @Router /api/site/{siteID}/return/{id} [put]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book returned successfully",
		Data: gin.H{
			"maPhieuMuon": maPhieuMuon,
			"site":        h.siteID,
		},
	})
}

// GetBorrows handles GET /api/site/{siteID}/borrows
// Implements FR4 - Tra cứu cục bộ (Librarian access to local site data)
// @Summary Get borrow records
// @Description Get all borrow records for the current site (Librarian only)
// @Tags Borrowing
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse{data=[]models.BorrowResponse} "Borrow records retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve borrow records"
// @Router /api/site/{siteID}/borrows [get]
func (h *BorrowHandler) GetBorrows(c *gin.Context) {
	borrows, err := h.borrowRepo.GetBorrows(h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrow records",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Borrow records retrieved successfully",
		Data: gin.H{
			"borrows": borrows,
			"site":    h.siteID,
			"count":   len(borrows),
		},
	})
}

// GetStats handles GET /api/manager/stats
// Implements FR6 - Thống kê toàn hệ thống (Manager only, distributed query)
// @Summary Get system statistics
// @Description Get comprehensive statistics across all sites in the distributed system (Manager only)
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse{data=models.SystemStats} "System statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Manager role required"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve system statistics"
// @Router /api/manager/stats [get]
func (h *BorrowHandler) GetStats(c *gin.Context) {
	stats, err := h.borrowRepo.GetSystemStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve system statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "System statistics retrieved successfully",
		Data: gin.H{
			"systemStats": stats,
			"coordinator": "Q1", // Indicating which site coordinated the query
		},
	})
}
