package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

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

// GetBooks handles GET /api/site/{siteID}/books
// Returns all books (replicated data) - any user can access
// @Summary Get all books
// @Description Get all books available in the library system (replicated data)
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse{data=[]models.Sach} "Books retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/books [get]
func (h *BookHandler) GetBooks(c *gin.Context) {
	books, err := h.bookRepo.GetBooks(h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve books",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Books retrieved successfully",
		Data: gin.H{
			"books": books,
			"site":  h.siteID,
			"count": len(books),
		},
	})
}

// GetBookCopies handles GET /api/site/{siteID}/book-copies
// Returns book copies from local site (fragmented data) - site-specific access required
// @Summary Get book copies at site
// @Description Get all book copies available at the current site (fragmented data)
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse{data=[]models.BookCopyResponse} "Book copies retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied to this site"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/book-copies [get]
func (h *BookHandler) GetBookCopies(c *gin.Context) {
	copies, err := h.bookRepo.GetBookCopies(h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve book copies",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copies retrieved successfully",
		Data: gin.H{
			"bookCopies": copies,
			"site":       h.siteID,
			"count":      len(copies),
		},
	})
}

// SearchBooks handles GET /api/manager/books/search
// Implements FR7 - Tìm kiếm sách toàn hệ thống (Manager only)
// @Summary Search books system-wide
// @Description Search for books across all sites in the distributed system (Manager only)
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param tenSach query string false "Book title search term"
// @Param tacGia query string false "Author search term"
// @Param isbn query string false "ISBN search term"
// @Success 200 {object} models.SuccessResponse{data=[]models.BookSearchResult} "Search results"
// @Failure 400 {object} models.ErrorResponse "Missing search parameters"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Manager role required"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/manager/books/search [get]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Books search completed successfully",
		Data: gin.H{
			"searchResults": results,
			"searchCriteria": gin.H{
				"tenSach": tenSach,
				"tacGia":  tacGia,
				"isbn":    isbn,
			},
			"totalFound": len(results),
		},
	})
}

// GetBookByISBN handles GET /api/books/{isbn}
// Get specific book details by ISBN
// @Summary Get book by ISBN
// @Description Get detailed information about a specific book by its ISBN
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse{data=models.Sach} "Book found"
// @Failure 400 {object} models.ErrorResponse "Invalid ISBN parameter"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Book not found"
// @Router /api/site/{siteID}/books/{isbn} [get]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book found successfully",
		Data: gin.H{
			"book": book,
			"site": h.siteID,
		},
	})
}

// GetAvailableBookCopy handles GET /api/books/{isbn}/available
// Get available copy of a book at current site
// @Summary Get available book copy
// @Description Get an available copy of a book at the current site
// @Tags Books
// @Produce json
// @Security BearerAuth
// @Param isbn path string true "Book ISBN"
// @Success 200 {object} models.SuccessResponse{data=models.BookCopyResponse} "Available copy found"
// @Failure 400 {object} models.ErrorResponse "Invalid ISBN parameter"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "No available copy found"
// @Router /api/site/{siteID}/books/{isbn}/available [get]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Available book copy found",
		Data: gin.H{
			"bookCopy": copy,
			"site":     h.siteID,
		},
	})
}

// CreateQuyenSach handles POST /api/site/{siteID}/book-copies
// Implements FR9 - CRUD quyển sách (ThuThu only)
// @Summary Create new book copy
// @Description Create a new book copy at the current site (ThuThu only)
// @Tags Book Copies
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param bookCopy body models.QuyenSach true "Book copy information"
// @Success 201 {object} models.SuccessResponse "Book copy created successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 409 {object} models.ErrorResponse "Book copy already exists"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/book-copies [post]
func (h *BookHandler) CreateQuyenSach(c *gin.Context) {
	var quyenSach models.QuyenSach
	if err := c.ShouldBindJSON(&quyenSach); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Details: err.Error(),
		})
		return
	}

	// Ensure the book copy belongs to the current site
	quyenSach.MaCN = h.siteID

	err := h.bookRepo.CreateQuyenSach(quyenSach)
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

// GetQuyenSach handles GET /api/site/{siteID}/book-copies/{maQuyenSach}
// Implements FR9 - CRUD quyển sách
// @Summary Get book copy by ID
// @Description Get book copy information by ID
// @Tags Book Copies
// @Produce json
// @Security BearerAuth
// @Param maQuyenSach path string true "Book copy ID"
// @Success 200 {object} models.SuccessResponse{data=models.QuyenSach} "Book copy found"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/book-copies/{maQuyenSach} [get]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy found",
		Data:    quyenSach,
	})
}

// UpdateQuyenSach handles PUT /api/site/{siteID}/book-copies/{maQuyenSach}
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
// @Router /api/site/{siteID}/book-copies/{maQuyenSach} [put]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy updated successfully",
		Data:    quyenSach,
	})
}

// DeleteQuyenSach handles DELETE /api/site/{siteID}/book-copies/{maQuyenSach}
// Implements FR9 - CRUD quyển sách (ThuThu only)
// @Summary Delete book copy
// @Description Delete a book copy (ThuThu only)
// @Tags Book Copies
// @Produce json
// @Security BearerAuth
// @Param maQuyenSach path string true "Book copy ID"
// @Success 200 {object} models.SuccessResponse "Book copy deleted successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - ThuThu only"
// @Failure 404 {object} models.ErrorResponse "Book copy not found"
// @Failure 409 {object} models.ErrorResponse "Cannot delete book copy currently on loan"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /api/site/{siteID}/book-copies/{maQuyenSach} [delete]
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

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Book copy deleted successfully",
	})
}
