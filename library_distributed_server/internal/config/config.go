package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Database DatabaseConfig
	Server   ServerConfig
	Auth     AuthConfig
	Sites    []SiteConfig
}

type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
}

type ServerConfig struct {
	Host         string
	Port         int
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	IdleTimeout  time.Duration
}

type AuthConfig struct {
	JWTSecret   string
	TokenExpiry time.Duration
}

type SiteConfig struct {
	SiteID   string
	Name     string
	Database string
	Host     string
	Port     int
}

func Load() (*Config, error) {
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: Error loading .env file: %v", err)
	}

	config := &Config{
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "10.211.55.3"),
			Port:     getEnvAsInt("DB_PORT", 1433),
			User:     getEnv("DB_USER", "sa"),
			Password: getEnv("DB_PASSWORD", ""),
			Database: getEnv("DB_NAME", "library_distributed"),
		},
		Server: ServerConfig{
			Host:         getEnv("SERVER_HOST", "localhost"),
			Port:         getEnvAsInt("SERVER_PORT", 8080),
			ReadTimeout:  getEnvAsDuration("SERVER_READ_TIMEOUT", 10*time.Second),
			WriteTimeout: getEnvAsDuration("SERVER_WRITE_TIMEOUT", 10*time.Second),
			IdleTimeout:  getEnvAsDuration("SERVER_IDLE_TIMEOUT", 60*time.Second),
		},
		Auth: AuthConfig{
			JWTSecret:   getEnv("JWT_SECRET", "your-secret-key"),
			TokenExpiry: getEnvAsDuration("JWT_TOKEN_EXPIRY", 24*time.Hour),
		},
		Sites: []SiteConfig{
			{
				SiteID:   "Q1",
				Name:     "Site_TV_Q1",
				Database: "ThuVienQ1",
				Host:     "10.211.55.3",
				Port:     1431,
			},
			{
				SiteID:   "Q3",
				Name:     "Site_TV_Q3",
				Database: "ThuVienQ3",
				Host:     "10.211.55.3",
				Port:     1433,
			},
		},
	}

	return config, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}

func (c *Config) GetConnectionString(siteID string) string {
	var site SiteConfig
	for _, s := range c.Sites {
		if s.SiteID == siteID {
			site = s
			break
		}
	}
	if site.SiteID == "" {
		// Default to first site if not found
		site = c.Sites[0]
	}
	return fmt.Sprintf("server=%s;port=%d;database=%s;user id=%s;password=%s;encrypt=disable",
		site.Host, site.Port, site.Database, c.Database.User, c.Database.Password)
}
