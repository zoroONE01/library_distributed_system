package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ReaderHandler struct {
	readerRepo repository.ReaderRepositoryInterface
	siteID     string
}

func NewReaderHandler(readerRepo repository.ReaderRepositoryInterface, siteID string) *ReaderHandler {
	return &ReaderHandler{
		readerRepo: readerRepo,
		siteID:     siteID,
	}
}

// CreateDocGia handles POST /api/readers and /api/site/{siteID}/readers
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Create new reader
// @Description Create a new reader at the user's site (ThuThu only)
// @Tags Readers
// @Accept json
// @Produce json
// @Param reader body models.DocGia true "Reader information"
// @Success 201 {object} models.SuccessResponse "Reader created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 500 {object} models.ErrorResponse "Failed to create reader"
// @Router /readers [post]
func (h *ReaderHandler) CreateDocGia(c *gin.Context) {
	ctx := c.Request.Context()
	userSite := c.GetString("maCN")

	var reader models.DocGia
	if err := c.ShouldBindJSON(&reader); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	// Set registration site to user's site
	reader.MaCNDangKy = userSite

	err := h.readerRepo.CreateReader(ctx, &reader, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Reader created successfully",
		Data:    reader,
	})
}

// GetDocGia handles GET /api/readers/{maDG}
// Implements FR8 - CRUD độc giả (role-based access)
// @Summary Get reader by ID
// @Description Get reader information by ID with role-based access control
// @Tags Readers
// @Produce json
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.SuccessResponse "Reader information"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve reader"
// @Router /readers/{maDG} [get]
func (h *ReaderHandler) GetDocGia(c *gin.Context) {
	ctx := c.Request.Context()
	maDG := c.Param("maDG")

	reader, err := h.readerRepo.GetReaderByID(ctx, maDG)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Reader not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader retrieved successfully",
		Data:    reader,
	})
}

// UpdateDocGia handles PUT /api/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Update reader
// @Description Update reader information (ThuThu only)
// @Tags Readers
// @Accept json
// @Produce json
// @Param maDG path string true "Reader ID"
// @Param reader body models.DocGia true "Updated reader information"
// @Success 200 {object} models.SuccessResponse "Reader updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Failed to update reader"
// @Router /readers/{maDG} [put]
func (h *ReaderHandler) UpdateDocGia(c *gin.Context) {
	ctx := c.Request.Context()
	maDG := c.Param("maDG")
	userSite := c.GetString("maCN")

	var reader models.DocGia
	if err := c.ShouldBindJSON(&reader); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	reader.MaDG = maDG

	err := h.readerRepo.UpdateReader(ctx, &reader, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader updated successfully",
		Data:    reader,
	})
}

// DeleteDocGia handles DELETE /api/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Delete reader
// @Description Delete reader (ThuThu only)
// @Tags Readers
// @Produce json
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.SuccessResponse "Reader deleted successfully"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Failed to delete reader"
// @Router /readers/{maDG} [delete]
func (h *ReaderHandler) DeleteDocGia(c *gin.Context) {
	ctx := c.Request.Context()
	maDG := c.Param("maDG")
	userSite := c.GetString("maCN")

	err := h.readerRepo.DeleteReader(ctx, maDG, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to delete reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader deleted successfully",
	})
}

// GetAllDocGia handles GET /api/readers
// Implements FR8 - CRUD độc giả with role-based filtering
// @Summary Get all readers
// @Description Get readers with role-based filtering (ThuThu: local site, QuanLy: all sites)
// @Tags Readers
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of readers"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve readers"
// @Router /readers [get]
func (h *ReaderHandler) GetAllDocGia(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")
	pagination := utils.ParsePaginationParams(c)

	var readers []*models.DocGia
	var total int
	var err error

	if userRole == "QUANLY" {
		// Managers can see all readers across all sites
		readers, total, err = h.readerRepo.GetAllReaders(ctx, &pagination)
	} else {
		// ThuThu can only see readers from their site
		readers, total, err = h.readerRepo.GetReadersBySite(ctx, userSite, &pagination)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(readers, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// SearchReaders handles GET /api/readers/search
// @Summary Search readers
// @Description Search for readers across sites (role-based access)
// @Tags Readers
// @Produce json
// @Param query query string true "Search query"
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "Search results"
// @Failure 400 {object} models.ErrorResponse "Invalid query"
// @Failure 500 {object} models.ErrorResponse "Search failed"
// @Router /readers/search [get]
func (h *ReaderHandler) SearchReaders(c *gin.Context) {
	ctx := c.Request.Context()
	query := c.Query("query")
	pagination := utils.ParsePaginationParams(c)

	if query == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Search query is required",
		})
		return
	}

	readers, total, err := h.readerRepo.SearchReaders(ctx, query, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Search failed",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(readers, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// GetReaderWithStats handles GET /api/readers/{maDG}/stats
// @Summary Get reader with statistics
// @Description Get reader information with borrowing statistics
// @Tags Readers
// @Produce json
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.SuccessResponse "Reader with statistics"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve reader statistics"
// @Router /readers/{maDG}/stats [get]
func (h *ReaderHandler) GetReaderWithStats(c *gin.Context) {
	ctx := c.Request.Context()
	maDG := c.Param("maDG")

	readerStats, err := h.readerRepo.GetReaderWithStats(ctx, maDG)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Reader not found or failed to retrieve statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader statistics retrieved successfully",
		Data:    readerStats,
	})
}

// GetReadersWithStats handles GET /api/readers/stats
// @Summary Get readers with statistics
// @Description Get all readers with borrowing statistics for the site
// @Tags Readers
// @Produce json
// @Success 200 {object} models.SuccessResponse "Readers with statistics"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve reader statistics"
// @Router /readers/stats [get]
func (h *ReaderHandler) GetReadersWithStats(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")
	userSite := c.GetString("maCN")

	// Determine which site to query
	siteID := h.siteID
	if userRole == "THUTHU" {
		siteID = userSite
	}

	readersStats, err := h.readerRepo.GetReadersWithStats(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve reader statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader statistics retrieved successfully",
		Data:    readersStats,
	})
}
