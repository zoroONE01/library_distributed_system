package handlers

import (
	"net/http"

	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/utils"

	"github.com/gin-gonic/gin"
)

type StatsHandler struct {
	statsRepo *repository.StatsRepository
	siteID    string
}

func NewStatsHandler(statsRepo *repository.StatsRepository, siteID string) *StatsHandler {
	return &StatsHandler{
		statsRepo: statsRepo,
		siteID:    siteID,
	}
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
	userRole := c.GetString("role")
	siteID := c.GetString("maCN")
	if siteID == "" {
		siteID = h.siteID
	}

	// Parse pagination parameters
	pagination := utils.ParsePaginationParams(c)
	searchTerm := utils.GetSearchTerm(c)

	result, err := h.statsRepo.GetReadersWithStatsPaginated(siteID, userRole, pagination, searchTerm)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve readers with statistics",
			Details: err.Error(),
		})
		return
	}

	// Create Flutter-compatible response
	listResponse := utils.CreateListResponse(result.Data, result.Pagination, result.TotalCount)

	c.JSON(http.StatusOK, listResponse)
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
	userRole := c.GetString("role")

	if userRole != "QUANLY" {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "Access denied",
			Details: "Manager role required to access system statistics",
		})
		return
	}

	stats, err := h.statsRepo.GetSystemStats(userRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to retrieve system statistics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, stats)
}
