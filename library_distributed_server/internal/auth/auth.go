package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	jwtSecret   []byte
	tokenExpiry time.Duration
}

// Claims - JWT token claims
// @Description JWT token claims for authentication
type Claims struct {
	UserID   string `json:"userID" example:"user123"`                    // User identifier
	Username string `json:"username" example:"thuthu01"`                 // Username
	Role     string `json:"role" example:"THUTHU" enums:"THUTHU,QUANLY"` // User role
	MaCN     string `json:"maCN" example:"Q1"`                           // Branch code for THUTHU users
	jwt.RegisteredClaims
}

// LoginRequest - Login request payload
// @Description User login credentials
type LoginRequest struct {
	Username string `json:"username" binding:"required" example:"thuthu01" validate:"required"`    // Username
	Password string `json:"password" binding:"required" example:"password123" validate:"required"` // Password
}

// LoginResponse - Login response payload
// @Description Successful login response with JWT access token only
type LoginResponse struct {
	AccessToken string `json:"accessToken" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."` // JWT access token
}

func NewAuthService(secret string, expiry time.Duration) *AuthService {
	return &AuthService{
		jwtSecret:   []byte(secret),
		tokenExpiry: expiry,
	}
}

func (s *AuthService) GenerateToken(userID, username, role, maCN string) (string, error) {
	claims := &Claims{
		UserID:   userID,
		Username: username,
		Role:     role,
		MaCN:     maCN,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.tokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

func (s *AuthService) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

func (s *AuthService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

func (s *AuthService) CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// Helper functions for authorization checks
func (s *AuthService) IsManager(claims *Claims) bool {
	return claims.Role == "QUANLY"
}

func (s *AuthService) IsLibrarian(claims *Claims) bool {
	return claims.Role == "THUTHU"
}

func (s *AuthService) CanAccessSite(claims *Claims, siteID string) bool {
	// Managers can access all sites
	if s.IsManager(claims) {
		return true
	}

	// Librarians can only access their own site
	if s.IsLibrarian(claims) {
		return claims.MaCN == siteID
	}

	return false
}
