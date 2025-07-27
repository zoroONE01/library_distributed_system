# Distributed Library Management System - Simplified Makefile

# --- Variables --------------------------------------------------
BACKEND_DIR  := library_distributed_server
FRONTEND_DIR := library_distributed_app

# --- Phony targets ---------------------------------------------
.PHONY: help start gen get clean

# Default: show help
help:
	@echo "Distributed Library Management System"
	@echo ""
	@echo "Available commands:"
	@echo "  make start - Start backend services only"
	@echo "  make gen   - Generate Flutter code (build_runner, assets, etc.)"
	@echo "  make get   - Get all dependencies (Go mod + Flutter pub get)"
	@echo "  make clean - Clean all build artifacts"
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


# Generate Flutter code (build_runner, assets, etc.)
gen:
	@echo "Generating Flutter code and assets..."
	@echo "1. Getting Flutter dependencies..."
	cd $(FRONTEND_DIR) && flutter pub get
	@echo "2. Running build_runner (generating code)..."
	cd $(FRONTEND_DIR) && flutter packages pub run build_runner build --delete-conflicting-outputs
	@echo "3. Generating app icon..."
	cd $(FRONTEND_DIR) && flutter pub run flutter_launcher_icons:main
	@echo "4. Generating native splash..."
	cd $(FRONTEND_DIR) && flutter pub run flutter_native_splash:create
	@echo "Flutter code generation completed!"

# Get all dependencies
get:
	@echo "Getting all dependencies..."
	@echo "1. Getting Go dependencies..."
	cd $(BACKEND_DIR) && go mod tidy && go mod download
	@echo "2. Generating Swagger documentation..."
	cd $(BACKEND_DIR) && make swagger
	@echo "3. Getting Flutter dependencies..."
	cd $(FRONTEND_DIR) && flutter pub get
	@echo "All dependencies restored and documentation generated!"

# Clean all artifacts
clean:
	@echo "Cleaning all build artifacts..."
	cd $(BACKEND_DIR) && make clean
	cd $(FRONTEND_DIR) && flutter clean
	rm -rf bin/