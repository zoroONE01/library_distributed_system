package handlers

import (
	"net/http"
	"strings"

	"library_distributed_server/internal/auth"
	"library_distributed_server/internal/models"
	"library_distributed_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *auth.AuthService
	userRepo    *repository.UserRepository
}

func NewAuthHandler(authService *auth.AuthService, userRepo *repository.UserRepository) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		userRepo:    userRepo,
	}
}

// Login handles user authentication (FR1, FR5)
// @Summary User login
// @Description Authenticate user and return JWT token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param credentials body auth.LoginRequest true "Login credentials"
// @Success 200 {object} auth.LoginResponse "Login successful"
// @Failure 400 {object} models.ErrorResponse "Invalid request format"
// @Failure 401 {object} models.ErrorResponse "Invalid credentials"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req auth.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request format",
			Details: err.Error(),
		})
		return
	}

	// Validate credentials
	if !h.userRepo.ValidateCredentials(req.Username, req.Password) {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Invalid username or password",
		})
		return
	}

	// Get user info
	user, err := h.userRepo.GetUserByUsername(req.Username)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "User not found",
		})
		return
	}

	// Generate JWT token
	token, err := h.authService.GenerateToken(user.ID, user.Username, user.Role, user.MaCN)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error: "Failed to generate token",
		})
		return
	}

	response := auth.LoginResponse{
		Token:    token,
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		MaCN:     user.MaCN,
	}

	c.JSON(http.StatusOK, response)
}

// RequireAuth middleware for JWT authentication
func (h *AuthHandler) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authorization header required",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		claims, err := h.authService.ValidateToken(tokenParts[1])
		if err != nil {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid token",
				Details: err.Error(),
			})
			c.Abort()
			return
		}

		// Store claims in context for later use
		c.Set("claims", claims)
		c.Next()
	}
}

// RequireRole middleware for role-based access control
func (h *AuthHandler) RequireRole(requiredRole string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authentication required",
			})
			c.Abort()
			return
		}

		userClaims, ok := claims.(*auth.Claims)
		if !ok {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error: "Invalid claims format",
			})
			c.Abort()
			return
		}

		if userClaims.Role != requiredRole {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error: "Insufficient permissions",
				Details: gin.H{
					"required": requiredRole,
					"actual":   userClaims.Role,
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireSiteAccess middleware for site-specific access control
func (h *AuthHandler) RequireSiteAccess(siteID string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authentication required",
			})
			c.Abort()
			return
		}

		userClaims, ok := claims.(*auth.Claims)
		if !ok {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Error: "Invalid claims format",
			})
			c.Abort()
			return
		}

		if !h.authService.CanAccessSite(userClaims, siteID) {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error: "Access denied to this site",
				Details: gin.H{
					"site":     siteID,
					"userRole": userClaims.Role,
					"userSite": userClaims.MaCN,
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// GetClaims helper function to extract claims from context
func GetClaims(c *gin.Context) (*auth.Claims, bool) {
	claims, exists := c.Get("claims")
	if !exists {
		return nil, false
	}

	userClaims, ok := claims.(*auth.Claims)
	return userClaims, ok
}
