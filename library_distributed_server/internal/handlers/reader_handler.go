package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type ReaderHandler struct {
	readerRepo *repository.ReaderRepository
	siteID     string
}

func NewReaderHandler(readerRepo *repository.ReaderRepository, siteID string) *ReaderHandler {
	return &ReaderHandler{
		readerRepo: readerRepo,
		siteID:     siteID,
	}
}

// CreateDocGia handles POST /api/site/{siteID}/readers
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Create new reader
// @Description Create a new reader at the current site (ThuThu only)
// @Tags Readers
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param reader body models.DocGia true "Reader information"
// @Success 201 {object} models.SuccessResponse "Reader created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 409 {object} models.ErrorResponse "Reader already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/readers [post]
func (h *ReaderHandler) CreateDocGia(c *gin.Context) {
	var docGia models.DocGia
	if err := c.ShouldBindJSON(&docGia); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Ensure the reader is registered to the current site
	docGia.MaCNDangKy = h.siteID

	err := h.readerRepo.CreateDocGia(docGia)
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
		Data:    docGia,
	})
}

// GetDocGia handles GET /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu/QuanLy)
// @Summary Get reader by ID
// @Description Get reader information by ID
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.SuccessResponse{data=models.DocGia} "Reader found"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/readers/{maDG} [get]
func (h *ReaderHandler) GetDocGia(c *gin.Context) {
	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	docGia, err := h.readerRepo.ReadDocGia(maDG, h.siteID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Reader not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader found",
		Data:    docGia,
	})
}

// UpdateDocGia handles PUT /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Update reader
// @Description Update reader information (ThuThu only)
// @Tags Readers
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Param reader body models.DocGia true "Updated reader information"
// @Success 200 {object} models.SuccessResponse "Reader updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/readers/{maDG} [put]
func (h *ReaderHandler) UpdateDocGia(c *gin.Context) {
	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	var docGia models.DocGia
	if err := c.ShouldBindJSON(&docGia); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Ensure the reader ID matches the URL parameter
	docGia.MaDG = maDG
	docGia.MaCNDangKy = h.siteID

	err := h.readerRepo.UpdateDocGia(docGia)
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
		Data:    docGia,
	})
}

// DeleteDocGia handles DELETE /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Delete reader
// @Description Delete a reader (ThuThu only)
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.SuccessResponse "Reader deleted successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 409 {object} models.ErrorResponse "Cannot delete reader with active borrows"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/readers/{maDG} [delete]
func (h *ReaderHandler) DeleteDocGia(c *gin.Context) {
	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	err := h.readerRepo.DeleteDocGia(maDG, h.siteID)
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

// GetAllDocGia handles GET /api/site/{siteID}/readers
// Implements FR8 - Local reader list (ThuThu access)
// @Summary Get all readers at site
// @Description Get all readers registered at the current site
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param search query string false "Search term for reader name"
// @Success 200 {object} models.SuccessResponse{data=[]models.DocGia} "Readers retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/readers [get]
func (h *ReaderHandler) GetAllDocGia(c *gin.Context) {
	searchTerm := c.Query("search")

	var readers []models.DocGia
	var err error

	if searchTerm != "" {
		readers, err = h.readerRepo.SearchDocGiaByName(searchTerm, h.siteID)
	} else {
		readers, err = h.readerRepo.GetAllDocGiaLocal(h.siteID)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Readers retrieved successfully",
		Data: gin.H{
			"readers": readers,
			"site":    h.siteID,
			"count":   len(readers),
		},
	})
}

// GetAllDocGiaSystemWide handles GET /api/manager/readers
// Implements FR11 - Global reader search (QuanLy only)
// @Summary Get all readers system-wide
// @Description Get all readers from all sites in the distributed system (Manager only)
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param search query string false "Search term for reader name"
// @Success 200 {object} models.SuccessResponse{data=[]models.DocGia} "Readers retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager only"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/manager/readers [get]
func (h *ReaderHandler) GetAllDocGiaSystemWide(c *gin.Context) {
	// Verify manager role
	userRole, exists := c.Get("role")
	if !exists || userRole != "QUANLY" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - Manager role required",
		})
		return
	}

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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "System-wide readers retrieved successfully",
		Data: gin.H{
			"readers": readers,
			"count":   len(readers),
		},
	})
}
