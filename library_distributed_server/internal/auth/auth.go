package auth

import (
    "errors"
    "fmt"
    "time"

    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
)

type Claims struct {
    UserID   string `json:"userId"`
    Username string `json:"username"`
    Role     string `json:"role"`
    MaCN     string `json:"maCN,omitempty"`
    jwt.RegisteredClaims
}

type AuthService struct {
    secretKey   []byte
    tokenExpiry time.Duration
}

func NewAuthService(secretKey string, tokenExpiry time.Duration) *AuthService {
    return &AuthService{
        secretKey:   []byte(secretKey),
        tokenExpiry: tokenExpiry,
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
            Subject:   userID,
        },
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(s.secretKey)
}

func (s *AuthService) ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return s.secretKey, nil
    })
    if err != nil {
        return nil, err
    }
    if !token.Valid {
        return nil, errors.New("invalid token")
    }
    claims, ok := token.Claims.(*Claims)
    if !ok {
        return nil, errors.New("invalid token claims")
    }
    return claims, nil
}

func (s *AuthService) HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

func (s *AuthService) CheckPassword(password, hashedPassword string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
    return err == nil
}

func (c *Claims) IsLibrarian() bool {
    return c.Role == "THUTHU"
}

func (c *Claims) IsManager() bool {
    return c.Role == "QUANLY"
}

func (c *Claims) CanAccessSite(siteID string) bool {
    if c.IsManager() {
        return true
    }
    return c.MaCN == siteID
}
