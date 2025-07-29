# Distributed Library Management System - Backend Makefile

.PHONY: help run swagger clean

help: ## Show this help message
	@echo "Available commands:"
	@echo "  make run     - Start all servers (Site Q1, Site Q3, Coordinator)"
	@echo "  make swagger - Generate Swagger documentation for all services"
	@echo "  make clean   - Clean build artifacts"

swagger: ## Generate Swagger documentation for all services
	@echo "Generating Swagger documentation for all services..."
	mkdir -p docs/site-q1
	~/go/bin/swag init -g cmd/site-q1/main.go -o docs/site-q1 --parseDependency --parseInternal
	mkdir -p docs/site-q3
	~/go/bin/swag init -g cmd/site-q3/main.go -o docs/site-q3 --parseDependency --parseInternal
	mkdir -p docs/coordinator
	~/go/bin/swag init -g cmd/coordinator/main.go -o docs/coordinator --parseDependency --parseInternal
	@echo "Swagger documentation generated for all services"
	@echo "- Site Q1 Swagger: http://localhost:8081/swagger/index.html"
	@echo "- Site Q3 Swagger: http://localhost:8083/swagger/index.html"

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

clean: ## Clean build artifacts
	rm -rf bin/
	rm -rf docs/
	rm -f coverage.out
	rm -f coverage.html