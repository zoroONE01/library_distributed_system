package utils

import (
	"math"
	"strconv"

	"library_distributed_server/internal/models"

	"github.com/gin-gonic/gin"
)

// PaginationParams holds pagination parameters parsed from query string
type PaginationParams struct {
	Page int // 0-based page number
	Size int // Items per page
}

// ParsePaginationParams parses pagination parameters from Gin context query params
// Returns default values if parameters are missing or invalid
func ParsePaginationParams(c *gin.Context) PaginationParams {
	const (
		defaultPage = 0
		defaultSize = 20
		maxSize     = 100
	)

	// Parse page parameter (0-based to match Flutter)
	pageStr := c.DefaultQuery("page", "0")
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 0 {
		page = defaultPage
	}

	// Parse size parameter
	sizeStr := c.DefaultQuery("size", strconv.Itoa(defaultSize))
	size, err := strconv.Atoi(sizeStr)
	if err != nil || size <= 0 {
		size = defaultSize
	}
	if size > maxSize {
		size = maxSize
	}

	return PaginationParams{
		Page: page,
		Size: size,
	}
}

// CalculateOffset calculates the SQL OFFSET value for pagination
func (p PaginationParams) CalculateOffset() int {
	return p.Page * p.Size
}

// CreatePagingInfo creates PagingInfo struct for API response
func CreatePagingInfo(page, size, totalCount int) models.PagingInfo {
	totalPages := int(math.Ceil(float64(totalCount) / float64(size)))
	if totalPages == 0 {
		totalPages = 1
	}

	return models.PagingInfo{
		Page:       page,
		Size:       size,
		TotalPages: totalPages,
	}
}

// CreateListResponse creates a standardized list response with pagination
func CreateListResponse(items interface{}, pagination PaginationParams, totalCount int) models.ListResponse {
	paging := CreatePagingInfo(pagination.Page, pagination.Size, totalCount)

	return models.ListResponse{
		Items:  items,
		Paging: paging,
	}
}

// GetSearchTerm extracts search term from query parameters
func GetSearchTerm(c *gin.Context) string {
	return c.Query("search")
}
