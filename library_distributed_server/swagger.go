// Package main Distributed Library Management System API
//
// This is a distributed library management system implemented in Go with horizontal fragmentation and full replication.
// The system manages multiple library branches with distributed database operations.
//
// Authentication System:
// The system uses SQL Server Authentication with the following test accounts:
//
// Site Q1 (Port 8081):
// - ThuThu_Q1 (password: ThuThu123@) - Librarian for Branch Q1 only
// - QuanLy (password: QuanLy456@) - System Manager (access to all branches)
//
// Site Q3 (Port 8083):
// - ThuThu_Q3 (password: ThuThu123@) - Librarian for Branch Q3 only
// - QuanLy (password: QuanLy456@) - System Manager (access to all branches)
//
// Role-Based Access Control:
// - THUTHU: Branch-specific operations (borrow, return, local queries)
// - QUANLY: System-wide operations (statistics, distributed queries, book transfers)
//
// Security Notes:
// - All passwords are stored in SQL Server using SQL Server Authentication
// - JWT tokens are used for API session management
// - Librarians can only access their designated branch data
// - Managers have cross-site query capabilities via distributed views
//
// Terms Of Service: N/A
//
// Schemes: http, https
// Host: localhost:8081
// BasePath: /
// Version: 1.0.0
// License: MIT
// License.URL: https://opensource.org/licenses/MIT
// Contact: Developer <dev@library.com>
//
// Consumes:
// - application/json
//
// Produces:
// - application/json
//
// SecurityDefinitions:
// BearerAuth:
//
//	type: apiKey
//	name: Authorization
//	in: header
//	description: "Type 'Bearer {token}' to correctly set the API Key"
//
// swagger:meta
package docs

//go:generate swag init -g cmd/site-q1/main.go -o docs
