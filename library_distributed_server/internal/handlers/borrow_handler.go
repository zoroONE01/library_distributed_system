package handlers

import (
	"context"
	"net/http"
	"strconv"

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

func (h *BorrowHandler) CreateBorrow(c *gin.Context) {
	var req struct {
		MaDG        string `json:"maDG"`
		MaQuyenSach string `json:"maQuyenSach"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	err := h.borrowRepo.CreateBorrow(context.Background(), h.siteID, req.MaDG, req.MaQuyenSach)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Borrow record created"})
}

func (h *BorrowHandler) ReturnBook(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid borrow ID"})
		return
	}
	err = h.borrowRepo.ReturnBook(context.Background(), h.siteID, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Book returned"})
}

func (h *BorrowHandler) GetBorrows(c *gin.Context) {
	borrows, err := h.borrowRepo.GetBorrows(context.Background(), h.siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, borrows)
}

func (h *BorrowHandler) GetStats(c *gin.Context) {
	stats, err := h.borrowRepo.GetSystemStats(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}
