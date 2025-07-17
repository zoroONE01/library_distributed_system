package handlers

import (
    "context"
    "net/http"
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

func (h *BookHandler) GetBooks(c *gin.Context) {
    books, err := h.bookRepo.GetBooks(context.Background(), h.siteID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, books)
}

func (h *BookHandler) GetBookCopies(c *gin.Context) {
    copies, err := h.bookRepo.GetBookCopies(context.Background(), h.siteID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, copies)
}

func (h *BookHandler) SearchBooks(c *gin.Context) {
    title := c.Query("title")
    if title == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Missing title parameter"})
        return
    }
    results, err := h.bookRepo.SearchBooksByTitle(context.Background(), title)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, results)
}
