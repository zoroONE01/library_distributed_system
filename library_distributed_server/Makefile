# Distributed Library Management System - Backend Makefile

.PHONY: help build run start swagger clean

help: ## Show this help message
	@echo "Available commands:"
	@echo "  make build   - Build all services"
	@echo "  make run     - Start all servers (Site Q1, Site Q3, Coordinator)"
	@echo "  make start   - Build and start all servers"
	@echo "  make swagger - Generate Swagger documentation for all services"
	@echo "  make clean   - Clean build artifacts"

swagger: ## Generate Swagger documentation for all services
	@echo "Generating Swagger documentation for all services..."
	@mkdir -p docs/site-q1 && \
	$(HOME)/go/bin/swag init -g cmd/site-q1/main.go -o docs/site-q1 && \
	mkdir -p docs/site-q3 && \
	$(HOME)/go/bin/swag init -g cmd/site-q3/main.go -o docs/site-q3 && \
	mkdir -p docs/coordinator && \
	$(HOME)/go/bin/swag init -g cmd/coordinator/main.go -o docs/coordinator
	@echo "Swagger documentation generated for all services"
	@echo "- Site Q1 Swagger: http://localhost:8081/swagger/index.html"
	@echo "- Site Q3 Swagger: http://localhost:8083/swagger/index.html"
	@echo "- Coordinator Swagger: http://localhost:8080/swagger/index.html"

build: ## Build all services
	@echo "Building all distributed library system services..."
	go build -o coordinator ./cmd/coordinator
	go build -o site-q1 ./cmd/site-q1
	go build -o site-q3 ./cmd/site-q3
	@echo "All services built successfully"
	@echo "- coordinator: Coordinator service binary"
	@echo "- site-q1: Site Q1 service binary"  
	@echo "- site-q3: Site Q3 service binary"

run: ## Start all servers concurrently
	@echo "Starting all distributed library system servers..."
	@echo "- Site Q1: http://localhost:8081"
	@echo "- Site Q3: http://localhost:8083"
	@echo "- Coordinator: http://localhost:8080"
	@echo ""
	@echo "Setting up environment variables..."
	@export JWT_SECRET="distributed-library-system-secret-key-2024" && \
	export JWT_TOKEN_EXPIRY="24h" && \
	echo "Press Ctrl+C to stop all servers" && \
	echo "" && \
	go run ./cmd/coordinator/main.go & \
	go run ./cmd/site-q1/main.go & \
	go run ./cmd/site-q3/main.go & \
	wait

start: swagger build run ## Generate docs, build and start all services

clean: ## Clean build artifacts
	rm -f coordinator site-q1 site-q3
	rm -rf bin/
	rm -rf docs/
	rm -f coverage.out
	rm -f coverage.html