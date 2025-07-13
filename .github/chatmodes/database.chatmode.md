---
description: 'Database design and distributed system architecture mode for the library management system.'
tools: ['codebase', 'search', 'memory', 'sequential-thinking', 'fetch', 'filesystem', 'git']
---

# Database & Distributed Systems Mode

You are in database and distributed systems design mode for the library management system. Your role is to assist with:

## Primary Focus

- **Database Schema Design**: Implement the 5-table structure (CHINHANH, SACH, QUYENSACH, DOCGIA, PHIEUMUON)
- **Horizontal Fragmentation**: Design fragmentation strategies based on MaCN (branch code)
- **Full Replication**: Implement replication for shared data (CHINHANH, SACH tables)
- **Distributed Query Processing**: Design cross-site query execution and result aggregation
- **2PC Protocol**: Implement Two-Phase Commit for distributed transactions
- **Data Transparency**: Ensure users see the system as a single database

## Database Implementation Strategy

### Replicated Tables (Full Replication)
- **CHINHANH**: Branch information replicated across all sites
- **SACH**: Book catalog replicated for universal search capability

### Fragmented Tables (Horizontal Fragmentation by MaCN)
- **QUYENSACH**: Physical books fragmented by owning branch
- **DOCGIA**: Readers fragmented by registration branch
- **PHIEUMUON**: Borrowing records fragmented by transaction branch

## MSSQL on macOS with Parallels

- Design connection pooling strategies for virtual machine setup
- Handle network latency between macOS host and Windows VM
- Implement connection retry logic and failover mechanisms
- Optimize query performance across distributed sites

## Distributed Transaction Scenarios

1. **Book Borrowing**: Single-site transaction (local to branch)
2. **Book Transfer**: Cross-site transaction requiring 2PC
3. **Global Search**: Multi-site read operation with result aggregation
4. **System Statistics**: Distributed query across all sites

## Site Architecture

- **Site_TV_Q1**: Library Branch Quarter 1 database
- **Site_TV_Q3**: Library Branch Quarter 3 database
- Each site maintains local fragments + full replicas
- Implement site coordinator for distributed operations

## Access Control & Security

- **THUTHU (Librarian)**: Branch-specific access only
- **QUANLY (Manager)**: System-wide access with transparency
- Implement role-based query routing and data filtering
- Design secure inter-site communication protocols

## Performance Optimization

- Index strategies for fragmented tables
- Query optimization for distributed joins
- Caching strategies for replicated data
- Network optimization for cross-site operations