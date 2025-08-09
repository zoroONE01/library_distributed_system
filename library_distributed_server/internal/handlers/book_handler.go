package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BookHandler struct {
	bookRepo *repository.BookRepository
	siteID   string
}

func NewBookHandler(bookRepo *repository.BookRepository, siteID string) *BookHandler {
	return &BookHandler{
		bookRepo: bookRepo,
		siteID:   siteID,
	}
}

// GetBooks handles GET /books
// Returns all books from the catalog with availability information and pagination
// @Summary Get all books with availability and pagination
// @Description Get all books available in the library system with availability count and pagination (enhanced for Flutter app)
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Success 200 {object} models.ListResponse "Books with availability retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /books [get]
func (h *BookHandler) GetBooks(c *gin.Context) {
	userRole := c.GetString("role")
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	// Parse pagination parameters
	pagination := utils.ParsePaginationParams(c)

	// Use enhanced paginated repository method
	result, err := h.bookRepo.GetBooksWithAvailabilityPaginated(siteID, userRole, pagination)
	if err != nil {
		// Fallback to regular books pagination if enhanced method fails
		fallbackResult, fallbackErr := h.bookRepo.GetBooksPaginated(h.siteID, pagination)
		if fallbackErr != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error:   "Failed to retrieve books",
				Details: err.Error(),
			})
			return
		}

		// Create response in Flutter-compatible format
		listResponse := utils.CreateListResponse(fallbackResult.Data, fallbackResult.Pagination, fallbackResult.TotalCount)
		c.JSON(http.StatusOK, listResponse)
		return
	}

	// Create response in Flutter-compatible format
	listResponse := utils.CreateListResponse(result.Data, result.Pagination, result.TotalCount)
	c.JSON(http.StatusOK, listResponse)
}

// GetBookCopies handles GET /book-copies and /site/{siteID}/book-copies
// Returns book copies based on user role with pagination - THUTHU sees local site, QUANLY sees all sites
// @Summary Get book copies based on user role with pagination
// @Description Get book copies with pagination - THUTHU sees local site only, QUANLY sees system-wide
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Param search query string false "Search term for book title, author, or ISBN"
// @Success 200 {object} models.ListResponse "Book copies retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /book-copies [get]
func (h *BookHandler) GetBookCopies(c *gin.Context) {
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

	var allCopies []models.QuyenSach
	var totalCount int

	// Role-based data access per requirements
	if claims.Role == "QUANLY" {
		// QuanLy can see book copies from all sites - query all sites and combine
		allConnections := map[string]string{"Q1": "Q1", "Q3": "Q3"}

		// For system-wide pagination, we need to handle this differently
		// Get all data and paginate in memory (not ideal for large datasets)
		for siteID := range allConnections {
			result, siteErr := h.bookRepo.GetBookCopiesPaginated(siteID, utils.PaginationParams{Page: 0, Size: 10000}, searchTerm)
			if siteErr != nil {
				// Log error but continue with other sites
				continue
			}
			if siteCopies, ok := result.Data.([]models.QuyenSach); ok {
				allCopies = append(allCopies, siteCopies...)
			}
		}

		totalCount = len(allCopies)

		// Apply pagination to combined results
		start := pagination.CalculateOffset()
		end := start + pagination.Size
		if start >= len(allCopies) {
			allCopies = []models.QuyenSach{}
		} else {
			if end > len(allCopies) {
				end = len(allCopies)
			}
			allCopies = allCopies[start:end]
		}

	} else if claims.Role == "THUTHU" {
		// ThuThu can only see book copies from their site
		result, err := h.bookRepo.GetBookCopiesPaginated(claims.MaCN, pagination, searchTerm)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error:   "Failed to retrieve book copies",
				Details: err.Error(),
			})
			return
		}

		if copies, ok := result.Data.([]models.QuyenSach); ok {
			allCopies = copies
		}
		totalCount = result.TotalCount

	} else {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Invalid user role for book copy access",
			Details: gin.H{
				"userRole": claims.Role,
				"allowed":  []string{"THUTHU", "QUANLY"},
			},
		})
		return
	}

	// Create Flutter-compatible response
	listResponse := utils.CreateListResponse(allCopies, pagination, totalCount)

	c.JSON(http.StatusOK, listResponse)
}

// SearchBooks handles book searching functionality
// This method provides search capabilities for books but is not directly exposed as a route
// It's used internally by other handlers that need book search functionality
func (h *BookHandler) SearchBooks(c *gin.Context) {
	tenSach := c.Query("tenSach")
	tacGia := c.Query("tacGia")
	isbn := c.Query("isbn")

	// At least one search parameter is required
	if tenSach == "" && tacGia == "" && isbn == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "At least one search parameter (tenSach, tacGia, or isbn) is required",
		})
		return
	}

	results, err := h.bookRepo.SearchBooksSystemWide(tenSach, tacGia, isbn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to search books system-wide",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, results)
}

// GetBookByISBN handles GET /books/{isbn}
// @Summary Get book by ISBN
// @Description Get detailed information about a specific book by its ISBN
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.Sach "Book found"
// @Failure 400 {object} models.ErrorResponse "Invalid ISBN parameter"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Router /books/{isbn} [get]
func (h *BookHandler) GetBookByISBN(c *gin.Context) {
	isbn := c.Param("isbn")
	if isbn == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "ISBN parameter is required",
		})
		return
	}

	book, err := h.bookRepo.GetBookByISBN(isbn, h.siteID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Book not found",
			Details: gin.H{"isbn": isbn},
		})
		return
	}

	c.JSON(http.StatusOK, book)
}

// GetAvailableBookCopy handles GET /books/{isbn}/available
// @Summary Get available book copy
// @Description Get an available copy of a book at the current site
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.QuyenSach "Available copy found"
// @Failure 400 {object} models.ErrorResponse "Invalid ISBN parameter"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "No available copy found"
// @Router /books/{isbn}/available [get]
func (h *BookHandler) GetAvailableBookCopy(c *gin.Context) {
	isbn := c.Param("isbn")
	if isbn == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "ISBN parameter is required",
		})
		return
	}

	copy, err := h.bookRepo.GetAvailableBookCopy(isbn, h.siteID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: "No available copy found at this site",
			Details: gin.H{
				"isbn": isbn,
				"site": h.siteID,
			},
		})
		return
	}

	c.JSON(http.StatusOK, copy)
}

// CreateQuyenSach handles POST /book-copies
// Implements FR9 - CRUD quyển sách (ThuThu only at their site)
// @Summary Create new book copy
// @Description Create a new book copy at the user's site (ThuThu only)
// @Tags Book Copies
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param bookCopy body models.QuyenSach true "Book copy information"
// @Success 201 {object} models.QuyenSach "Book copy created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 409 {object} models.ErrorResponse "Book copy already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /book-copies [post]
func (h *BookHandler) CreateQuyenSach(c *gin.Context) {
	// Get user role and site from JWT token
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Operation validation is handled by middleware, but double-check
	if claims.Role != "THUTHU" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error: "Access denied - only THUTHU can create book copies",
		})
		return
	}

	var quyenSach models.QuyenSach
	if err := c.ShouldBindJSON(&quyenSach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Ensure the book copy belongs to the user's site (cannot create at other sites)
	quyenSach.MaCN = claims.MaCN

	err := h.bookRepo.CreateQuyenSach(quyenSach)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, quyenSach)
}

// GetQuyenSach handles GET /site/{siteID}/book-copies/{maQuyenSach}
// Implements FR9 - CRUD quyển sách
// @Summary Get book copy by ID
// @Description Get book copy information by ID
// @Tags Book Copies
// @Produce json
// @Security BearerAuth
// @Param maQuyenSach path string true "Book copy ID"
// @Success 200 {object} models.QuyenSach "Book copy found"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /site/{siteID}/book-copies/{maQuyenSach} [get]
func (h *BookHandler) GetQuyenSach(c *gin.Context) {
	maQuyenSach := c.Param("maQuyenSach")
	if maQuyenSach == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Book copy ID is required",
		})
		return
	}

	quyenSach, err := h.bookRepo.ReadQuyenSach(maQuyenSach, h.siteID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Book copy not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, quyenSach)
}

// UpdateQuyenSach handles PUT /site/{siteID}/book-copies/{maQuyenSach}
// Implements FR9 - CRUD quyển sách (ThuThu only)
// @Summary Update book copy
// @Description Update book copy information (ThuThu only)
// @Tags Book Copies
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param maQuyenSach path string true "Book copy ID"
// @Param bookCopy body models.QuyenSach true "Updated book copy information"
// @Success 200 {object} models.SuccessResponse "Book copy updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /site/{siteID}/book-copies/{maQuyenSach} [put]
func (h *BookHandler) UpdateQuyenSach(c *gin.Context) {
	maQuyenSach := c.Param("maQuyenSach")
	if maQuyenSach == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Book copy ID is required",
		})
		return
	}

	var quyenSach models.QuyenSach
	if err := c.ShouldBindJSON(&quyenSach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Ensure the book copy ID matches the URL parameter
	quyenSach.MaQuyenSach = maQuyenSach
	quyenSach.MaCN = h.siteID

	err := h.bookRepo.UpdateQuyenSach(quyenSach)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, quyenSach)
}

// DeleteQuyenSach handles DELETE /site/{siteID}/book-copies/{maQuyenSach}
// Implements FR9 - CRUD quyển sách (ThuThu only)
// @Summary Delete book copy
// @Description Delete a book copy (ThuThu only)
// @Tags Book Copies
// @Produce json
// @Security BearerAuth
// @Param maQuyenSach path string true "Book copy ID"
// @Success 204 "Book copy deleted successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 409 {object} models.ErrorResponse "Cannot delete book copy currently on loan"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /site/{siteID}/book-copies/{maQuyenSach} [delete]
func (h *BookHandler) DeleteQuyenSach(c *gin.Context) {
	maQuyenSach := c.Param("maQuyenSach")
	if maQuyenSach == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Book copy ID is required",
		})
		return
	}

	err := h.bookRepo.DeleteQuyenSach(maQuyenSach, h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to delete book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}
