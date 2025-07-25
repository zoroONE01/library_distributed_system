package utils

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response represents a standard API response
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// SuccessResponse sends a successful response
func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, Response{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// ErrorResponse sends an error response
func ErrorResponse(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, Response{
		Success: false,
		Error:   message,
	})
}

// LogStructured logs structured data in JSON format
func LogStructured(level string, message string, data interface{}) {
	logData := map[string]interface{}{
		"level":   level,
		"message": message,
		"data":    data,
	}
	
	jsonData, _ := json.Marshal(logData)
	log.Println(string(jsonData))
}

// LogInfo logs info level message
func LogInfo(message string, data interface{}) {
	LogStructured("INFO", message, data)
}

// LogError logs error level message
func LogError(message string, data interface{}) {
	LogStructured("ERROR", message, data)
}

// LogWarning logs warning level message
func LogWarning(message string, data interface{}) {
	LogStructured("WARNING", message, data)
}

// CORS middleware for development
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}