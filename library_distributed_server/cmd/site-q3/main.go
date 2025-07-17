package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"library_distributed_server/internal/auth"
	"library_distributed_server/internal/config"
	"library_distributed_server/internal/handlers"
	"library_distributed_server/internal/repository"
	"library_distributed_server/pkg/database"

	"github.com/gin-gonic/gin"
)

const SITE_ID = "Q3"

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load configuration:", err)
	}
	authService := auth.NewAuthService(cfg.Auth.JWTSecret, cfg.Auth.TokenExpiry)
	userRepo := repository.NewUserRepository(cfg)
	bookRepo := repository.NewBookRepository(cfg)
	borrowRepo := repository.NewBorrowRepository(cfg)
	authHandler := handlers.NewAuthHandler(authService, userRepo)
	bookHandler := handlers.NewBookHandler(bookRepo, SITE_ID)
	borrowHandler := handlers.NewBorrowHandler(borrowRepo, SITE_ID)
	router := setupRouter(authHandler, bookHandler, borrowHandler)
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Server.Port+1), // Q3 chạy port kế tiếp
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  cfg.Server.IdleTimeout,
	}
	go func() {
		log.Printf("Site %s server starting on port %d", SITE_ID, cfg.Server.Port+1)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Server failed to start:", err)
		}
	}()
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}
	database.GetPool().CloseAll()
	log.Println("Server exited")
}

func setupRouter(authHandler *handlers.AuthHandler, bookHandler *handlers.BookHandler, borrowHandler *handlers.BorrowHandler) *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	router := gin.Default()
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "healthy",
			"site":   SITE_ID,
			"time":   time.Now(),
		})
	})
	router.POST("/auth/login", authHandler.Login)
	api := router.Group("/api")
	api.Use(authHandler.RequireAuth())
	{
		siteRoutes := api.Group("/site/" + SITE_ID)
		siteRoutes.Use(authHandler.RequireSiteAccess(SITE_ID))
		{
			siteRoutes.GET("/books", bookHandler.GetBooks)
			siteRoutes.GET("/book-copies", bookHandler.GetBookCopies)
			siteRoutes.POST("/borrow", borrowHandler.CreateBorrow)
			siteRoutes.PUT("/return/:id", borrowHandler.ReturnBook)
			siteRoutes.GET("/borrows", borrowHandler.GetBorrows)
		}
		managerRoutes := api.Group("/manager")
		managerRoutes.Use(authHandler.RequireRole("QUANLY"))
		{
			managerRoutes.GET("/books/search", bookHandler.SearchBooks)
			managerRoutes.GET("/stats", borrowHandler.GetStats)
		}
	}
	return router
}
