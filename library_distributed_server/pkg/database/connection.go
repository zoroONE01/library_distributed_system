package database

import (
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	_ "github.com/denisenkom/go-mssqldb"
)

type ConnectionPool struct {
	connections map[string]*sql.DB
	mutex       sync.RWMutex
}

var (
	pool *ConnectionPool
	once sync.Once
)

func GetPool() *ConnectionPool {
	once.Do(func() {
		pool = &ConnectionPool{
			connections: make(map[string]*sql.DB),
		}
	})
	return pool
}

func (cp *ConnectionPool) GetConnection(siteID string, connectionString string) (*sql.DB, error) {
	cp.mutex.RLock()
	if conn, exists := cp.connections[siteID]; exists {
		cp.mutex.RUnlock()
		return conn, nil
	}
	cp.mutex.RUnlock()

	cp.mutex.Lock()
	defer cp.mutex.Unlock()

	if conn, exists := cp.connections[siteID]; exists {
		return conn, nil
	}

	db, err := sql.Open("mssql", connectionString)
	if err != nil {
		return nil, fmt.Errorf("failed to open connection to site %s: %w", siteID, err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := testConnectionWithRetry(db, 3); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to connect to site %s: %w", siteID, err)
	}

	cp.connections[siteID] = db
	log.Printf("Successfully connected to site %s", siteID)
	return db, nil
}

func testConnectionWithRetry(db *sql.DB, maxRetries int) error {
	for i := 0; i < maxRetries; i++ {
		if err := db.Ping(); err == nil {
			return nil
		}
		time.Sleep(time.Duration(i+1) * time.Second)
	}
	return fmt.Errorf("connection failed after %d retries", maxRetries)
}

func (cp *ConnectionPool) CloseAll() {
	cp.mutex.Lock()
	defer cp.mutex.Unlock()

	for siteID, conn := range cp.connections {
		if err := conn.Close(); err != nil {
			log.Printf("Error closing connection to site %s: %v", siteID, err)
		}
	}
	cp.connections = make(map[string]*sql.DB)
}
