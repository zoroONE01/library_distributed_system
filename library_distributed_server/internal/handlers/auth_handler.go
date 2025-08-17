package handlers

import (
	"fmt"
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
		c.Set("maCN", claims.MaCN) // Set user's site for easy access
		c.Set("role", claims.Role) // Set user's role for easy access
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

// RequireSiteAccess middleware for site-specific access control based on user role and token claims
func (h *AuthHandler) RequireSiteAccess(siteID string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := GetClaims(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authentication required",
			})
			c.Abort()
			return
		}

		// Apply role-based site access control per requirements
		if !h.authService.CanAccessSite(claims, siteID) {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error: "Access denied to this site",
				Details: gin.H{
					"site":         siteID,
					"userRole":     claims.Role,
					"userSite":     claims.MaCN,
					"requirements": "THUTHU can only access their branch site, QUANLY can access all sites",
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireRoleOrSiteAccess middleware that allows access based on role OR site access
// Used for endpoints that should be accessible to managers globally or librarians locally
func (h *AuthHandler) RequireRoleOrSiteAccess(role string, siteID string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := GetClaims(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authentication required",
			})
			c.Abort()
			return
		}

		// Check if user has the required role (e.g., QUANLY can access everything)
		hasRole := claims.Role == role
		// Check if user can access the specific site (e.g., THUTHU can access their site)
		hasSiteAccess := h.authService.CanAccessSite(claims, siteID)

		if !hasRole && !hasSiteAccess {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error: "Access denied",
				Details: gin.H{
					"requiredRole":    role,
					"requiredSite":    siteID,
					"userRole":        claims.Role,
					"userSite":        claims.MaCN,
					"accessCondition": fmt.Sprintf("Need %s role OR access to site %s", role, siteID),
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// ValidateOperationAccess validates if user can perform specific operations based on their role and site
func (h *AuthHandler) ValidateOperationAccess(operation string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := GetClaims(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Authentication required",
			})
			c.Abort()
			return
		}

		// Set operation context for handlers to use
		c.Set("operation", operation)
		c.Set("userRole", claims.Role)
		c.Set("userSite", claims.MaCN)
		c.Set("maCN", claims.MaCN) // Add this for backward compatibility

		// Specific operation validations based on requirements
		switch operation {
		case "CREATE_BOOK_COPY", "UPDATE_BOOK_COPY", "DELETE_BOOK_COPY":
			// FR9: Only THUTHU can CRUD book copies at their site
			if claims.Role != "THUTHU" {
				c.JSON(http.StatusForbidden, models.ErrorResponse{
					Error: fmt.Sprintf("Access denied - %s operation requires THUTHU role", operation),
					Details: gin.H{
						"operation": operation,
						"userRole":  claims.Role,
						"required":  "THUTHU",
					},
				})
				c.Abort()
				return
			}
		case "BORROW_BOOK", "RETURN_BOOK":
			// FR2, FR3: Only THUTHU can handle borrowing operations
			if claims.Role != "THUTHU" {
				c.JSON(http.StatusForbidden, models.ErrorResponse{
					Error: fmt.Sprintf("Access denied - %s operation requires THUTHU role", operation),
					Details: gin.H{
						"operation": operation,
						"userRole":  claims.Role,
						"required":  "THUTHU",
					},
				})
				c.Abort()
				return
			}
		case "CREATE_READER", "UPDATE_READER", "DELETE_READER":
			// FR8: Only THUTHU can CRUD readers at their site
			if claims.Role != "THUTHU" {
				c.JSON(http.StatusForbidden, models.ErrorResponse{
					Error: fmt.Sprintf("Access denied - %s operation requires THUTHU role", operation),
					Details: gin.H{
						"operation": operation,
						"userRole":  claims.Role,
						"required":  "THUTHU",
					},
				})
				c.Abort()
				return
			}
		case "SYSTEM_STATS", "GLOBAL_SEARCH", "MANAGE_CATALOG":
			// FR6, FR7, FR10: Only QUANLY can perform system-wide operations
			if claims.Role != "QUANLY" {
				c.JSON(http.StatusForbidden, models.ErrorResponse{
					Error: fmt.Sprintf("Access denied - %s operation requires QUANLY role", operation),
					Details: gin.H{
						"operation": operation,
						"userRole":  claims.Role,
						"required":  "QUANLY",
					},
				})
				c.Abort()
				return
			}
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
