package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ManagerHandler struct {
	bookRepo   repository.BookRepositoryInterface
	borrowRepo repository.BorrowRepositoryInterface
	readerRepo repository.ReaderRepositoryInterface
}

func NewManagerHandler(
	bookRepo repository.BookRepositoryInterface,
	borrowRepo repository.BorrowRepositoryInterface,
	readerRepo repository.ReaderRepositoryInterface,
) *ManagerHandler {
	return &ManagerHandler{
		bookRepo:   bookRepo,
		borrowRepo: borrowRepo,
		readerRepo: readerRepo,
	}
}

// CreateSach handles POST /manager/books
// Implements FR10 - Create book in catalog using 2PC
// @Summary Create book in catalog
// @Description Create a new book in the system catalog using 2PC protocol (Manager only)
// @Tags Manager
// @Accept json
// @Produce json
// @Param book body models.Sach true "Book information"
// @Success 201 {object} models.SuccessResponse "Book created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 500 {object} models.ErrorResponse "Failed to create book"
// @Router /manager/books [post]
func (h *ManagerHandler) CreateSach(c *gin.Context) {
	ctx := c.Request.Context()

	var book models.Sach
	if err := c.ShouldBindJSON(&book); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	err := h.bookRepo.CreateBook(ctx, &book)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to create book using 2PC protocol",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, models.SuccessResponse{
		Success: true,
		Message: "Book created successfully using 2PC protocol",
		Data:    book,
	})
}

// GetSach handles GET /manager/books/{isbn}
// @Summary Get book by ISBN
// @Description Get book information from catalog (Manager only)
// @Tags Manager
// @Produce json
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse "Book information"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve book"
// @Router /manager/books/{isbn} [get]
func (h *ManagerHandler) GetSach(c *gin.Context) {
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

// SearchAvailableBooks handles GET /manager/books/search
// Implements FR7 - Distributed book search
// @Summary Search books across all sites
// @Description Search for books across all sites with availability information (Manager only)
// @Tags Manager
// @Produce json
// @Param query query string true "Search query"
// @Success 200 {object} models.SuccessResponse "Search results with availability"
// @Failure 400 {object} models.ErrorResponse "Invalid query"
// @Failure 500 {object} models.ErrorResponse "Search failed"
// @Router /manager/books/search [get]
func (h *ManagerHandler) SearchAvailableBooks(c *gin.Context) {
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
			Error:   "Failed to search books across sites",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book search completed successfully",
		Data:    results,
	})
}

// GetSystemStats handles GET /manager/statistics
// Implements FR6 - System-wide statistics
// @Summary Get system-wide statistics
// @Description Get comprehensive statistics across all sites (Manager only)
// @Tags Manager
// @Produce json
// @Success 200 {object} models.SuccessResponse "System statistics"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve statistics"
// @Router /manager/statistics [get]
func (h *ManagerHandler) GetSystemStats(c *gin.Context) {
	ctx := c.Request.Context()

	// Get system-wide book statistics
	bookStats, err := h.bookRepo.GetBooksWithAvailability(ctx, "")
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve book statistics",
			Details: err.Error(),
		})
		return
	}

	// Combine all statistics
	stats := map[string]interface{}{
		"books":    bookStats,
		"message":  "System statistics retrieved successfully",
		"sites":    []string{"Q1", "Q3"},
		"protocol": "Distributed Raw SQL Queries",
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "System statistics retrieved successfully",
		Data:    stats,
	})
}

// GetAllReaders handles GET /manager/readers
// Implements FR11 - Global reader access
// @Summary Get all readers across all sites
// @Description Get readers from all sites with pagination (Manager only)
// @Tags Manager
// @Produce json
// @Param page query int false "Page number (0-based, default 0)"
// @Param size query int false "Page size (default 20)"
// @Success 200 {object} models.ListResponse "List of all readers"
// @Failure 500 {object} models.ErrorResponse "Failed to retrieve readers"
// @Router /manager/readers [get]
func (h *ManagerHandler) GetAllReaders(c *gin.Context) {
	ctx := c.Request.Context()
	pagination := utils.ParsePaginationParams(c)

	readers, total, err := h.readerRepo.GetAllReaders(ctx, &pagination)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers from all sites",
			Details: err.Error(),
		})
		return
	}

	listResponse := utils.CreateListResponse(readers, pagination, total)
	c.JSON(http.StatusOK, listResponse)
}

// UpdateBook handles PUT /manager/books/{isbn}
// @Summary Update book in catalog
// @Description Update book information using 2PC protocol (Manager only)
// @Tags Manager
// @Accept json
// @Produce json
// @Param isbn path string true "Book ISBN"
// @Param book body models.Sach true "Updated book information"
// @Success 200 {object} models.SuccessResponse "Book updated successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Failure 500 {object} models.ErrorResponse "Failed to update book"
// @Router /manager/books/{isbn} [put]
func (h *ManagerHandler) UpdateBook(c *gin.Context) {
	ctx := c.Request.Context()
	isbn := c.Param("isbn")

	var book models.Sach
	if err := c.ShouldBindJSON(&book); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	book.ISBN = isbn

	err := h.bookRepo.UpdateBook(ctx, &book)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to update book using 2PC protocol",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book updated successfully using 2PC protocol",
		Data:    book,
	})
}

// DeleteBook handles DELETE /manager/books/{isbn}
// @Summary Delete book from catalog
// @Description Delete book from catalog using 2PC protocol (Manager only)
// @Tags Manager
// @Produce json
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse "Book deleted successfully"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Failure 500 {object} models.ErrorResponse "Failed to delete book"
// @Router /manager/books/{isbn} [delete]
func (h *ManagerHandler) DeleteBook(c *gin.Context) {
	ctx := c.Request.Context()
	isbn := c.Param("isbn")

	err := h.bookRepo.DeleteBook(ctx, isbn)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to delete book using 2PC protocol",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book deleted successfully using 2PC protocol",
	})
}

// TransferBookCopy handles POST /manager/transfer
// @Summary Transfer book copy between sites
// @Description Transfer a book copy from one site to another using 2PC protocol
// @Tags Manager
// @Accept json
// @Produce json
// @Param request body models.TransferBookRequest true "Transfer request"
// @Success 200 {object} models.SuccessResponse "Book copy transferred successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 500 {object} models.ErrorResponse "Failed to transfer book copy"
// @Router /manager/transfer [post]
func (h *ManagerHandler) TransferBookCopy(c *gin.Context) {
	ctx := c.Request.Context()

	var req models.TransferBookRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	err := h.bookRepo.TransferBookCopy(ctx, req.MaQuyenSach, req.FromSite, req.ToSite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to transfer book copy using 2PC protocol",
			Details: err.Error(),
		})
		return
	}

	response := models.TransferBookResponse{
		Message:     "Book copy transferred successfully using 2PC protocol",
		MaQuyenSach: req.MaQuyenSach,
		FromSite:    req.FromSite,
		ToSite:      req.ToSite,
		Protocol:    "Two-Phase Commit (2PC)",
		Coordinator: "Distributed Transaction Coordinator",
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy transferred successfully",
		Data:    response,
	})
}
