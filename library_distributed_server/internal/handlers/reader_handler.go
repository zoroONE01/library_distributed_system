package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

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

// CreateDocGia handles POST /api/readers and /api/site/{siteID}/readers
// Implements FR8 - CRUD độc giả (ThuThu only)
// @Summary Create new reader
// @Description Create a new reader at the user's site (ThuThu only)
// @Tags Readers
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param reader body models.DocGia true "Reader information"
// @Success 201 {object} models.DocGia "Reader created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 409 {object} models.ErrorResponse "Reader already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /readers [post]
func (h *ReaderHandler) CreateDocGia(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Operation access validation is handled by middleware, but ensure we have site info
	if claims.Role == "THUTHU" && claims.MaCN == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Invalid token: THUTHU role requires site information",
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

	// For THUTHU: Ensure the reader is registered to their site
	// For QUANLY: Use the site specified in the request or default to current handler site
	if claims.Role == "THUTHU" {
		docGia.MaCNDangKy = claims.MaCN
	} else if docGia.MaCNDangKy == "" {
		docGia.MaCNDangKy = h.siteID // fallback to handler site
	}

	err := h.readerRepo.CreateDocGia(docGia)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, docGia)
}

// GetDocGia handles GET /api/readers/{maDG} and /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu/QuanLy with role-based access)
// @Summary Get reader by ID
// @Description Get reader information by ID - access based on user role and reader location
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Success 200 {object} models.DocGia "Reader found"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - reader not at user's site"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /readers/{maDG} [get]
func (h *ReaderHandler) GetDocGia(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	var docGia *models.DocGia
	var err error

	// Role-based access control per requirements
	if claims.Role == "QUANLY" {
		// FR11: QuanLy can access any reader system-wide - try all sites
		connections := map[string]string{"Q1": "Q1", "Q3": "Q3"}
		for siteID := range connections {
			docGia, err = h.readerRepo.ReadDocGia(maDG, siteID)
			if err == nil {
				break // Found reader at this site
			}
		}
	} else if claims.Role == "THUTHU" {
		// FR8: ThuThu can only access readers from their site
		docGia, err = h.readerRepo.ReadDocGia(maDG, claims.MaCN)
	} else {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Invalid user role for reader access",
			Details: gin.H{
				"userRole": claims.Role,
				"allowed":  []string{"THUTHU", "QUANLY"},
			},
		})
		return
	}

	if err != nil || docGia == nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: "Reader not found",
			Details: gin.H{
				"maDG":     maDG,
				"userRole": claims.Role,
				"userSite": claims.MaCN,
			},
		})
		return
	}

	// Additional access check for THUTHU - ensure reader belongs to their site
	if claims.Role == "THUTHU" && docGia.MaCNDangKy != claims.MaCN {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - reader not registered at your site",
			Details: gin.H{
				"readerSite": docGia.MaCNDangKy,
				"userSite":   claims.MaCN,
			},
		})
		return
	}

	c.JSON(http.StatusOK, *docGia)
}

// UpdateDocGia handles PUT /api/readers/{maDG} and /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only at their site)
// @Summary Update reader
// @Description Update reader information (ThuThu only at their site)
// @Tags Readers
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Param reader body models.DocGia true "Updated reader information"
// @Success 200 {object} models.DocGia "Reader updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only or wrong site"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /readers/{maDG} [put]
func (h *ReaderHandler) UpdateDocGia(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Operation validation is handled by middleware, but double-check site access
	if claims.Role != "THUTHU" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - only THUTHU can update readers",
		})
		return
	}

	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	// First check if reader exists and belongs to THUTHU's site
	existingReader, err := h.readerRepo.ReadDocGia(maDG, claims.MaCN)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: "Reader not found at your site",
			Details: gin.H{
				"maDG":     maDG,
				"userSite": claims.MaCN,
			},
		})
		return
	}

	if existingReader.MaCNDangKy != claims.MaCN {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - reader not registered at your site",
			Details: gin.H{
				"readerSite": existingReader.MaCNDangKy,
				"userSite":   claims.MaCN,
			},
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

	// Ensure the reader ID matches the URL parameter and belongs to user's site
	docGia.MaDG = maDG
	docGia.MaCNDangKy = claims.MaCN // Cannot change registration site

	err = h.readerRepo.UpdateDocGia(docGia)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, docGia)
}

// DeleteDocGia handles DELETE /api/readers/{maDG} and /api/site/{siteID}/readers/{maDG}
// Implements FR8 - CRUD độc giả (ThuThu only at their site)
// @Summary Delete reader
// @Description Delete a reader (ThuThu only at their site)
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param maDG path string true "Reader ID"
// @Success 204 "Reader deleted successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only or wrong site"
// @Failure 404 {object} models.ErrorResponse "Reader not found"
// @Failure 409 {object} models.ErrorResponse "Cannot delete reader with active borrows"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /readers/{maDG} [delete]
func (h *ReaderHandler) DeleteDocGia(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Operation validation is handled by middleware, but double-check site access
	if claims.Role != "THUTHU" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - only THUTHU can delete readers",
		})
		return
	}

	maDG := c.Param("maDG")
	if maDG == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Reader ID is required",
		})
		return
	}

	// First check if reader exists and belongs to THUTHU's site
	existingReader, err := h.readerRepo.ReadDocGia(maDG, claims.MaCN)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: "Reader not found at your site",
			Details: gin.H{
				"maDG":     maDG,
				"userSite": claims.MaCN,
			},
		})
		return
	}

	if existingReader.MaCNDangKy != claims.MaCN {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - reader not registered at your site",
			Details: gin.H{
				"readerSite": existingReader.MaCNDangKy,
				"userSite":   claims.MaCN,
			},
		})
		return
	}

	err = h.readerRepo.DeleteDocGia(maDG, claims.MaCN)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to delete reader",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

// GetAllDocGia handles GET /api/readers and /api/site/{siteID}/readers
// Implements FR8 - Local reader list (ThuThu) and FR11 - System-wide access (QuanLy) with pagination
// @Summary Get readers based on user role with pagination
// @Description Get readers with pagination - THUTHU sees local site only, QUANLY sees all sites
// @Tags Readers
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Param search query string false "Search term for reader name or ID"
// @Success 200 {object} models.ListResponse "Readers retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /readers [get]
func (h *ReaderHandler) GetAllDocGia(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Parse pagination parameters
	pagination := utils.ParsePaginationParams(c)
	searchTerm := utils.GetSearchTerm(c)

	var result *repository.PaginatedResult
	var err error

	// Role-based data access per requirements
	if claims.Role == "QUANLY" {
		// FR11: QuanLy can see all readers system-wide
		result, err = h.readerRepo.GetAllDocGiaSystemWidePaginated(pagination, searchTerm)
	} else if claims.Role == "THUTHU" {
		// FR8: ThuThu can only see readers from their site
		result, err = h.readerRepo.GetAllDocGiaLocalPaginated(claims.MaCN, pagination, searchTerm)
	} else {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Invalid user role for reader access",
			Details: gin.H{
				"userRole": claims.Role,
				"allowed":  []string{"THUTHU", "QUANLY"},
			},
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers",
			Details: err.Error(),
		})
		return
	}

	// Create Flutter-compatible response
	listResponse := utils.CreateListResponse(result.Data, result.Pagination, result.TotalCount)

	c.JSON(http.StatusOK, listResponse)
}

// GetAllDocGiaSystemWide handles system-wide reader queries
// This method provides system-wide reader search capabilities but is not directly exposed as a route
// It's used internally by manager handler that needs system-wide reader data
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

	c.JSON(http.StatusOK, readers)
}
