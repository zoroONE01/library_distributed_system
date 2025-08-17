package handlers

import (
	"net/http"
	"strconv"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BookHandler struct {
	bookRepo repository.BookRepositoryInterface
	siteID   string
}

func NewBookHandler(bookRepo repository.BookRepositoryInterface, siteID string) *BookHandler {
	return &BookHandler{
		bookRepo: bookRepo,
		siteID:   siteID,
	}
}

// GetBooks handles GET /books
// @Summary Get all books
// @Description Retrieve all books in the catalog
// @Tags Books
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of books"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve books"
// @Router /books [get]
func (h *BookHandler) GetBooks(c *gin.Context) {
	ctx := c.Request.Context()
	pagination := utils.ParsePaginationParams(c)

	books, total, err := h.bookRepo.GetAllBooks(ctx, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve books",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(books, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// GetBookCopies handles GET /book-copies
// @Summary Get book copies
// @Description Retrieve book copies for the current site
// @Tags Book Copies
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of book copies"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve book copies"
// @Router /book-copies [get]
func (h *BookHandler) GetBookCopies(c *gin.Context) {
	ctx := c.Request.Context()
	pagination := utils.ParsePaginationParams(c)

	bookCopies, total, err := h.bookRepo.GetBookCopiesBySite(ctx, h.siteID, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve book copies",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(bookCopies, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// SearchBooks handles GET /books/search
// @Summary Search books across all sites
// @Description Search for books across all sites with availability info
// @Tags Books
// @Produce json
// @Param query query string true "Search query"
// @Success 200 {object} models.SuccessResponse "Search results"
// @Failure 400 {object} models.ErrorResponse "Invalid query"
// @Failure 500 {object} models.ErrorResponse "Search failed"
// @Router /books/search [get]
func (h *BookHandler) SearchBooks(c *gin.Context) {
	ctx := c.Request.Context()
	query := c.Query("query")

	if query == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error: "Search query is required",
		})
		return
	}

	results, err := h.bookRepo.SearchAvailableBooks(ctx, query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Search failed",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Search completed successfully",
		Data:    results,
	})
}

// GetBookByISBN handles GET /books/:isbn
// @Summary Get book by ISBN
// @Description Get detailed information about a book by its ISBN
// @Tags Books
// @Produce json
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse "Book details"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve book"
// @Router /books/{isbn} [get]
func (h *BookHandler) GetBookByISBN(c *gin.Context) {
	ctx := c.Request.Context()
	isbn := c.Param("isbn")

	book, err := h.bookRepo.GetBookByISBN(ctx, isbn)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Book not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book retrieved successfully",
		Data:    book,
	})
}

// GetAvailableBookCopy handles GET /books/:isbn/available
// @Summary Check book availability
// @Description Check if a book is available at the current site
// @Tags Books
// @Produce json
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse "Availability info"
// @Failure 404 {object} models.ErrorResponse "No available copies"
// @Failure 500 {object} models.ErrorResponse "Failed to check availability"
// @Router /books/{isbn}/available [get]
func (h *BookHandler) GetAvailableBookCopy(c *gin.Context) {
	ctx := c.Request.Context()
	isbn := c.Param("isbn")

	count, err := h.bookRepo.CheckBookAvailability(ctx, isbn, h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to check availability",
			Details: err.Error(),
		})
		return
	}

	if count == 0 {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error: "No available copies at this site",
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book is available",
		Data:    map[string]int{"availableCount": count},
	})
}

// CreateQuyenSach handles POST /book-copies
// @Summary Create book copy
// @Description Create a new book copy at the current site
// @Tags Book Copies
// @Accept json
// @Produce json
// @Param bookCopy body models.QuyenSach true "Book copy information"
// @Success 201 {object} models.SuccessResponse "Book copy created"
// @Failure 400 {object} models.ErrorResponse "Invalid request"
// @Failure 500 {object} models.ErrorResponse "Failed to create book copy"
// @Router /book-copies [post]
func (h *BookHandler) CreateQuyenSach(c *gin.Context) {
	ctx := c.Request.Context()
	userSite := c.GetString("maCN")

	var quyenSach models.QuyenSach
	if err := c.ShouldBindJSON(&quyenSach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	// Set site to user's site
	quyenSach.MaCN = userSite

	err := h.bookRepo.CreateBookCopy(ctx, &quyenSach, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Book copy created successfully",
		Data:    quyenSach,
	})
}

// GetQuyenSach handles GET /book-copies/:maQuyenSach
// @Summary Get book copy by ID
// @Description Get detailed information about a book copy
// @Tags Book Copies
// @Produce json
// @Param maQuyenSach path string true "Book copy ID"
// @Success 200 {object} models.SuccessResponse "Book copy details"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve book copy"
// @Router /book-copies/{maQuyenSach} [get]
func (h *BookHandler) GetQuyenSach(c *gin.Context) {
	ctx := c.Request.Context()
	maQuyenSach := c.Param("maQuyenSach")

	bookCopy, err := h.bookRepo.GetBookCopyByID(ctx, maQuyenSach)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Book copy not found",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy retrieved successfully",
		Data:    bookCopy,
	})
}

// UpdateQuyenSach handles PUT /book-copies/:maQuyenSach
// @Summary Update book copy
// @Description Update book copy information
// @Tags Book Copies
// @Accept json
// @Produce json
// @Param maQuyenSach path string true "Book copy ID"
// @Param bookCopy body models.QuyenSach true "Updated book copy information"
// @Success 200 {object} models.SuccessResponse "Book copy updated"
// @Failure 400 {object} models.ErrorResponse "Invalid request"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Failed to update book copy"
// @Router /book-copies/{maQuyenSach} [put]
func (h *BookHandler) UpdateQuyenSach(c *gin.Context) {
	ctx := c.Request.Context()
	maQuyenSach := c.Param("maQuyenSach")
	userSite := c.GetString("maCN")

	var quyenSach models.QuyenSach
	if err := c.ShouldBindJSON(&quyenSach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	quyenSach.MaQuyenSach = maQuyenSach

	err := h.bookRepo.UpdateBookCopy(ctx, &quyenSach, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy updated successfully",
		Data:    quyenSach,
	})
}

// DeleteQuyenSach handles DELETE /book-copies/:maQuyenSach
// @Summary Delete book copy
// @Description Delete a book copy
// @Tags Book Copies
// @Produce json
// @Param maQuyenSach path string true "Book copy ID"
// @Success 200 {object} models.SuccessResponse "Book copy deleted"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Failed to delete book copy"
// @Router /book-copies/{maQuyenSach} [delete]
func (h *BookHandler) DeleteQuyenSach(c *gin.Context) {
	ctx := c.Request.Context()
	maQuyenSach := c.Param("maQuyenSach")
	userSite := c.GetString("maCN")

	err := h.bookRepo.DeleteBookCopy(ctx, maQuyenSach, userSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to delete book copy",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy deleted successfully",
	})
}

// Helper functions for pagination
func parsePage(pageStr string) int {
	if pageStr == "" {
		return 0
	}
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 0 {
		return 0
	}
	return page
}

func parseSize(sizeStr string) int {
	if sizeStr == "" {
		return 20
	}
	size, err := strconv.Atoi(sizeStr)
	if err != nil || size <= 0 {
		return 20
	}
	if size > 100 {
		return 100
	}
	return size
}
