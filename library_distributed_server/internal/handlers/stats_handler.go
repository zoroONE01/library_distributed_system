package handlers

import (
	"net/http"
	"strconv"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type StatsHandler struct {
	statsRepo repository.StatsRepositoryInterface
	siteID    string
}

func NewStatsHandler(statsRepo repository.StatsRepositoryInterface, siteID string) *StatsHandler {
	return &StatsHandler{
		statsRepo: statsRepo,
		siteID:    siteID,
	}
}

// GetSiteStats handles GET /stats/site
// Site-specific statistics for both THUTHU and QUANLY
// @Summary Get site statistics
// @Description Get statistics for current site (available to both roles)
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse "Site statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/site [get]
func (h *StatsHandler) GetSiteStats(c *gin.Context) {
	ctx := c.Request.Context()
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	stats, err := h.statsRepo.GetSiteStatistics(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve site statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Site statistics retrieved successfully",
		Data:    stats,
	})
}

// GetSystemStats handles GET /stats/system
// Manager-only endpoint for system-wide statistics
// @Summary Get system statistics
// @Description Get comprehensive system statistics across all sites (Manager only)
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SystemStatsResponse "System statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager role required"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/system [get]
func (h *StatsHandler) GetSystemStats(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")

	if userRole != "QUANLY" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "Access denied",
			Details: "Manager role required to access system statistics",
		})
		return
	}

	stats, err := h.statsRepo.GetSystemStatistics(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve system statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// GetDistributedStats handles GET /stats/distributed
// Manager-only endpoint for distributed system statistics
// @Summary Get distributed system statistics
// @Description Get distributed system health and statistics (Manager only)
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse "Distributed statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 403 {object} models.ErrorResponse "Access denied - Manager role required"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/distributed [get]
func (h *StatsHandler) GetDistributedStats(c *gin.Context) {
	ctx := c.Request.Context()
	userRole := c.GetString("role")

	if userRole != "QUANLY" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "Access denied",
			Details: "Manager role required to access distributed statistics",
		})
		return
	}

	stats, err := h.statsRepo.GetDistributedStatistics(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve distributed statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Distributed statistics retrieved successfully",
		Data:    stats,
	})
}

// GetPopularBooks handles GET /stats/popular-books
// Popular books statistics with role-based scope
// @Summary Get popular books statistics
// @Description Get popular books based on borrowing frequency
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Param limit query int false "Number of books to return" default(10)
// @Success 200 {object} models.SuccessResponse "Popular books statistics retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/popular-books [get]
func (h *StatsHandler) GetPopularBooks(c *gin.Context) {
	ctx := c.Request.Context()

	// Parse limit parameter
	limit := 10
	if limitParam := c.Query("limit"); limitParam != "" {
		if parsedLimit, err := strconv.Atoi(limitParam); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	books, err := h.statsRepo.GetPopularBooksAcrossSites(ctx, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve popular books statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Popular books statistics retrieved successfully",
		Data:    books,
	})
}

// GetBorrowTrends handles GET /stats/borrow-trends
// Borrowing trends analysis
// @Summary Get borrowing trends
// @Description Get borrowing trends for site analysis
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Param days query int false "Number of days to analyze" default(30)
// @Success 200 {object} models.SuccessResponse "Borrow trends retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/borrow-trends [get]
func (h *StatsHandler) GetBorrowTrends(c *gin.Context) {
	ctx := c.Request.Context()
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	// Parse days parameter
	days := 30
	if daysParam := c.Query("days"); daysParam != "" {
		if parsedDays, err := strconv.Atoi(daysParam); err == nil && parsedDays > 0 {
			days = parsedDays
		}
	}

	trends, err := h.statsRepo.GetBorrowTrends(ctx, siteID, days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve borrow trends",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Borrow trends retrieved successfully",
		Data:    trends,
	})
}

// GetSystemHealth handles GET /stats/health
// System health monitoring
// @Summary Get system health
// @Description Get system health status across all sites
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.SuccessResponse "System health retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/health [get]
func (h *StatsHandler) GetSystemHealth(c *gin.Context) {
	ctx := c.Request.Context()

	health, err := h.statsRepo.GetSystemHealth(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve system health",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "System health retrieved successfully",
		Data:    health,
	})
}

// GetReadersWithStats handles GET /stats/readers
// Enhanced endpoint for Flutter app with reader statistics and pagination
// @Summary Get readers with statistics and pagination
// @Description Get readers with borrowing statistics with pagination (enhanced for Flutter app)
// @Tags Statistics
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (0-based)" default(0)
// @Param size query int false "Items per page" default(20)
// @Param search query string false "Search term for reader name or ID"
// @Success 200 {object} models.ListResponse "Readers with stats retrieved successfully"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /stats/readers [get]
func (h *StatsHandler) GetReadersWithStats(c *gin.Context) {
	ctx := c.Request.Context()
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	// Get site-specific book statistics as reader stats
	bookStats, err := h.statsRepo.GetSiteBookStatistics(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve reader statistics",
			Details: err.Error(),
		})
		return
	}

	// Get reader statistics
	readerStats, err := h.statsRepo.GetSiteReaderStatistics(ctx, siteID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve reader statistics",
			Details: err.Error(),
		})
		return
	}

	// Combine stats
	combinedStats := map[string]interface{}{
		"book_stats":   bookStats,
		"reader_stats": readerStats,
		"site_id":      siteID,
	}

	c.JSON(http.StatusOK, models.SuccessResponse{
		Success: true,
		Message: "Reader statistics retrieved successfully",
		Data:    combinedStats,
	})
}
