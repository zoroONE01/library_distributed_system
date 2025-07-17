package main

import (
	"library_distributed_server/internal/distributed"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "coordinator healthy", "time": time.Now()})
	})
	router.POST("/2pc/transfer-book", distributed.HandleTransferBook2PC)
	srv := &http.Server{
		Addr:    ":8082",
		Handler: router,
	}
	go func() {
		log.Println("Coordinator server starting on port 8082")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Coordinator failed to start:", err)
		}
	}()
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Coordinator shutting down...")
	srv.Close()
}
