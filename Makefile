# Makefile for Distributed Library Management System

# --- Variables --------------------------------------------------
# Commands
GO          := go
FLUTTER     := flutter

# Directories
BACKEND_DIR  := library_distributed_server
FRONTEND_DIR := library_distributed_app
BIN_DIR      := bin

# Database (MSSQL in Parallels VM)
DB_HOST     ?= 10.211.55.3
DB_PORT     ?= 1433

# Go build flags
GO_LDFLAGS  := -ldflags="-s -w"

# --- Phony targets ---------------------------------------------
.PHONY: all backend frontend build-backend build-frontend \
        run-backend run-frontend \
        site-q1 site-q3 coordinator \
        test-backend test-frontend clean

# Default: build everything
all: build-backend build-frontend

# Build backend services
build-backend: $(BIN_DIR)/site-q1 $(BIN_DIR)/site-q3 $(BIN_DIR)/coordinator

$(BIN_DIR)/site-q1:
    @echo "Building site-q1 service..."
    @mkdir -p $(BIN_DIR)
    cd $(BACKEND_DIR)/cmd/site-q1 && \
    $(GO) build $(GO_LDFLAGS) -o ../../../$(BIN_DIR)/site-q1

$(BIN_DIR)/site-q3:
    @echo "Building site-q3 service..."
    @mkdir -p $(BIN_DIR)
    cd $(BACKEND_DIR)/cmd/site-q3 && \
    $(GO) build $(GO_LDFLAGS) -o ../../../$(BIN_DIR)/site-q3

$(BIN_DIR)/coordinator:
    @echo "Building coordinator service..."
    @mkdir -p $(BIN_DIR)
    cd $(BACKEND_DIR)/cmd/coordinator && \
    $(GO) build $(GO_LDFLAGS) -o ../../../$(BIN_DIR)/coordinator

# Build Flutter frontend (web + desktop)
build-frontend:
    @echo "Fetching Flutter dependencies..."
    cd $(FRONTEND_DIR) && $(FLUTTER) pub get
    @echo "Building Flutter web..."
    cd $(FRONTEND_DIR) && $(FLUTTER) build web
    @echo "Building Flutter macOS binary..."
    cd $(FRONTEND_DIR) && $(FLUTTER) build macos --release

# Run backend services (export DB vars)
run-backend: export DB_HOST=$(DB_HOST)
run-backend: export DB_PORT=$(DB_PORT)
run-backend: site-q1 site-q3 coordinator

site-q1:
    @echo "Starting site-q1 on localhost:8081..."
    DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) \
    $(BIN_DIR)/site-q1 &

site-q3:
    @echo "Starting site-q3 on localhost:8083..."
    DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) \
    $(BIN_DIR)/site-q3 &

coordinator:
    @echo "Starting coordinator on localhost:8090..."
    DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) \
    $(BIN_DIR)/coordinator &

# Run Flutter frontend locally (web)
run-frontend:
    cd $(FRONTEND_DIR) && $(FLUTTER) run -d chrome

# Tests
test-backend:
    cd $(BACKEND_DIR) && $(GO) test ./...

test-frontend:
    cd $(FRONTEND_DIR) && $(FLUTTER) test

# Clean build artifacts
clean:
    @echo "Cleaning binaries and build outputs..."
    rm -rf $(BIN_DIR)
    cd $(FRONTEND_DIR) && $(FLUTTER) clean