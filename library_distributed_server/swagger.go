// Package main Distributed Library Management System API
//
// This is a distributed library management system implemented in Go with horizontal fragmentation and full replication.
// The system manages multiple library branches with distributed database operations.
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
//   type: apiKey
//   name: Authorization
//   in: header
//   description: "Type 'Bearer {token}' to correctly set the API Key"
//
// swagger:meta
package main

//go:generate swag init -g cmd/site-q1/main.go -o docs