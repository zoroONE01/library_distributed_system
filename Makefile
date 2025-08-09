# Distributed Library Management System - Simplified Makefile

# --- Variables --------------------------------------------------
BACKEND_DIR  := library_distributed_server
FRONTEND_DIR := library_distributed_app

# --- Phony targets ---------------------------------------------
.PHONY: help all start server app

# Default: clean and get dependencies
all: server app

# Show help
help:
	@echo "Distributed Library Management System"
	@echo ""
	@echo "Available commands:"
	@echo "  make        - Clean and setup the entire system (backend + frontend, includes Flutter code generation)"
	@echo "  make server - Clean and setup only backend (includes Swagger docs)"
	@echo "  make app    - Clean and setup only frontend (includes build_runner, icons, splash)"
	@echo "  make start  - Start backend services only"
	@echo ""
	@echo "Backend services will be available at:"
	@echo "  Site Q1:     http://localhost:8081"
	@echo "  Site Q3:     http://localhost:8083"
	@echo "  Coordinator: http://localhost:8080"



start:
	@echo "Starting all distributed library system services..."
	@echo "- Site Q1: http://localhost:8081"
	@echo "- Site Q3: http://localhost:8083"
	@echo "- Coordinator: http://localhost:8080"
	@echo ""
	@echo "Press Ctrl+C to stop all services"
	@echo ""
	@echo "Swagger UI endpoints:"
	@echo "- Site Q1 Swagger: http://localhost:8081/swagger/index.html"
	@echo "- Site Q3 Swagger: http://localhost:8083/swagger/index.html"
	@echo "- Coordinator Swagger: http://localhost:8080/swagger/index.html"
	cd $(BACKEND_DIR) && make run

# Clean and get backend dependencies only
server:
	@echo "Cleaning and getting backend dependencies..."
	@echo "1. Cleaning backend artifacts..."
	cd $(BACKEND_DIR) && make clean
	@echo "2. Getting Go dependencies..."
	cd $(BACKEND_DIR) && go mod tidy && go mod download
	@echo "3. Generating Swagger documentation..."
	cd $(BACKEND_DIR) && make swagger
	@echo "Backend dependencies restored and documentation generated!"

# Clean and get frontend dependencies only
app:
	@echo "Cleaning and getting frontend dependencies..."
	@echo "1. Cleaning Flutter artifacts..."
	cd $(FRONTEND_DIR) && flutter clean
	@echo "2. Getting Flutter dependencies..."
	cd $(FRONTEND_DIR) && flutter pub get
	@echo "3. Running build_runner (generating code)..."
	cd $(FRONTEND_DIR) && flutter packages pub run build_runner build --delete-conflicting-outputs
	@echo "Frontend dependencies restored and all code generated!"