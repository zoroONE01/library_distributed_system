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
// @Description Authenticate user using stored procedure and return JWT access token only
// @Tags Authentication
// @Accept json
// @Produce json
// @Param credentials body auth.LoginRequest true "Login credentials"
// @Success 200 {object} auth.LoginResponse "Login successful with access token"
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

	// Validate credentials using sp_Login stored procedure
	if !h.userRepo.ValidateCredentials(req.Username, req.Password) {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Invalid username or password",
		})
		return
	}

	// Get user info using sp_GetUserInfo stored procedure
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
		AccessToken: token,
	}

	c.JSON(http.StatusOK, response)
}

// Logout handles user logout
// @Summary User logout
// @Description Logout user (invalidate token on client side)
// @Tags Authentication
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]string "Logout successful"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Router /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	// In a stateless JWT system, logout is handled client-side
	// by removing the token. We can add token blacklisting here if needed.
	c.JSON(http.StatusOK, gin.H{
		"message": "Logout successful",
	})
}

// GetCurrentUser handles getting current user profile
// @Summary Get current user profile
// @Description Get detailed information about the currently authenticated user including role, branch, and permissions
// @Tags Authentication
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.UserInfo "User profile information"
// @Failure 401 {object} models.ErrorResponse "Unauthorized"
// @Failure 500 {object} models.ErrorResponse "Internal server error"
// @Router /auth/profile [get]
func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
	// Get claims from middleware
	claims, exists := GetClaims(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Authentication required",
		})
		return
	}

	// Get detailed user information using sp_GetUserInfo
	userInfo, err := h.userRepo.GetCurrentUserInfo(claims.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get user information",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, userInfo)
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
