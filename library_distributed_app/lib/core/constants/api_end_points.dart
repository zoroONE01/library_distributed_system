class ApiEndPoints {
  // =========================================================================
  // BASE URLS FOR EACH SERVICE
  // =========================================================================
  
  /// Coordinator service base URL (port 8080)
  static const coordinatorBaseUrl = 'http://localhost:8080';
  
  /// Site Q1 service base URL (port 8081)
  static const siteQ1BaseUrl = 'http://localhost:8081';
  
  /// Site Q3 service base URL (port 8083)
  static const siteQ3BaseUrl = 'http://localhost:8083';

  // =========================================================================
  // AUTHENTICATION ENDPOINTS (Available on all services)
  // =========================================================================
  
  /// User login endpoint - Coordinator
  static const login = '$coordinatorBaseUrl/auth/login';
  
  /// User login endpoint - Site Q1
  static const loginQ1 = '$siteQ1BaseUrl/auth/login';
  
  /// User login endpoint - Site Q3  
  static const loginQ3 = '$siteQ3BaseUrl/auth/login';

  // =========================================================================
  // COORDINATOR ENDPOINTS (Port 8080 - Distributed Transactions)
  // =========================================================================
  
  /// Transfer book between sites using 2PC protocol
  static const transferBook = '$coordinatorBaseUrl/api/coordinator/transfer-book';

  // =========================================================================
  // MANAGER ENDPOINTS (Port 8080 - System-wide access)
  // =========================================================================
  
  /// Search books across all sites (Manager only)
  static const managerBookSearch = '$coordinatorBaseUrl/api/manager/books/search';
  
  /// Get system statistics across all sites (Manager only)
  static const managerStats = '$coordinatorBaseUrl/api/manager/stats';

  // =========================================================================
  // SITE Q1 ENDPOINTS (Port 8081)
  // =========================================================================
  
  /// Get all books at Site Q1 (replicated data)
  static const siteQ1Books = '$siteQ1BaseUrl/api/site/Q1/books';
  
  /// Get book by ISBN at Site Q1
  /// Usage: ${ApiEndPoints.siteQ1BookByISBN('123456789')}
  static String siteQ1BookByISBN(String isbn) => '$siteQ1BaseUrl/api/site/Q1/books/$isbn';
  
  /// Get available copy of a book at Site Q1
  /// Usage: ${ApiEndPoints.siteQ1BookAvailable('123456789')}
  static String siteQ1BookAvailable(String isbn) => '$siteQ1BaseUrl/api/site/Q1/books/$isbn/available';
  
  /// Get all book copies at Site Q1 (fragmented data)
  static const siteQ1BookCopies = '$siteQ1BaseUrl/api/site/Q1/book-copies';
  
  /// Create borrow transaction at Site Q1
  static const siteQ1Borrow = '$siteQ1BaseUrl/api/site/Q1/borrow';
  
  /// Return borrowed book at Site Q1
  /// Usage: ${ApiEndPoints.siteQ1Return('123')}
  static String siteQ1Return(String borrowID) => '$siteQ1BaseUrl/api/site/Q1/return/$borrowID';
  
  /// Get borrow history at Site Q1
  static const siteQ1BorrowHistory = '$siteQ1BaseUrl/api/site/Q1/borrow-history';
  
  /// Get reader information at Site Q1
  /// Usage: ${ApiEndPoints.siteQ1Reader('DG001')}
  static String siteQ1Reader(String readerID) => '$siteQ1BaseUrl/api/site/Q1/readers/$readerID';
  
  /// Get all branches at Site Q1 (replicated data)
    static const siteQ1Branches = '$siteQ1BaseUrl/api/site/Q1/branches';

  // =========================================================================
  // SITE Q3 ENDPOINTS (Port 8083)
  // =========================================================================
  
  /// Get all books at Site Q3 (replicated data)
  static const siteQ3Books = '$siteQ3BaseUrl/api/site/Q3/books';
  
  /// Get book by ISBN at Site Q3
  /// Usage: ${ApiEndPoints.siteQ3BookByISBN('123456789')}
  static String siteQ3BookByISBN(String isbn) => '$siteQ3BaseUrl/api/site/Q3/books/$isbn';
  
  /// Get available copy of a book at Site Q3
  /// Usage: ${ApiEndPoints.siteQ3BookAvailable('123456789')}
  static String siteQ3BookAvailable(String isbn) => '$siteQ3BaseUrl/api/site/Q3/books/$isbn/available';
  
  /// Get all book copies at Site Q3 (fragmented data)
  static const siteQ3BookCopies = '$siteQ3BaseUrl/api/site/Q3/book-copies';
  
  /// Create borrow transaction at Site Q3
  static const siteQ3Borrow = '$siteQ3BaseUrl/api/site/Q3/borrow';
  
  /// Return borrowed book at Site Q3
  /// Usage: ${ApiEndPoints.siteQ3Return('123')}
  static String siteQ3Return(String borrowID) => '$siteQ3BaseUrl/api/site/Q3/return/$borrowID';
  
  /// Get borrow history at Site Q3
  static const siteQ3BorrowHistory = '$siteQ3BaseUrl/api/site/Q3/borrow-history';
  
  /// Get reader information at Site Q3
  /// Usage: ${ApiEndPoints.siteQ3Reader('DG001')}
  static String siteQ3Reader(String readerID) => '$siteQ3BaseUrl/api/site/Q3/readers/$readerID';
  
  /// Get all branches at Site Q3 (replicated data)
  static const siteQ3Branches = '$siteQ3BaseUrl/api/site/Q3/branches';

  // =========================================================================
  // DYNAMIC SITE ENDPOINTS (Helper methods)
  // =========================================================================
  
  /// Get base URL for a specific site
  static String getSiteBaseUrl(String siteID) {
    switch (siteID) {
      case 'Q1':
        return siteQ1BaseUrl;
      case 'Q3':
        return siteQ3BaseUrl;
      default:
        throw ArgumentError('Invalid site ID: $siteID');
    }
  }
  
  /// Get books endpoint for a specific site
  static String getSiteBooks(String siteID) => '${getSiteBaseUrl(siteID)}/api/site/$siteID/books';
  
  /// Get book by ISBN for a specific site
  static String getSiteBookByISBN(String siteID, String isbn) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/books/$isbn';
  
  /// Get available book copy for a specific site
  static String getSiteBookAvailable(String siteID, String isbn) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/books/$isbn/available';
  
  /// Get book copies for a specific site
  static String getSiteBookCopies(String siteID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/book-copies';
  
  /// Get borrow endpoint for a specific site
  static String getSiteBorrow(String siteID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/borrow';
  
  /// Get return endpoint for a specific site
  static String getSiteReturn(String siteID, String borrowID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/return/$borrowID';
  
  /// Get borrow history for a specific site
  static String getSiteBorrowHistory(String siteID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/borrow-history';
  
  /// Get reader information for a specific site
  static String getSiteReader(String siteID, String readerID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/readers/$readerID';
  
  /// Get branches for a specific site
  static String getSiteBranches(String siteID) => 
      '${getSiteBaseUrl(siteID)}/api/site/$siteID/branches';

  // =========================================================================
  // SITE CONSTANTS
  // =========================================================================
  
  /// Available site IDs in the distributed system
  static const String siteQ1 = 'Q1';
  static const String siteQ3 = 'Q3';
  
  /// List of all available sites
  static const List<String> allSites = [siteQ1, siteQ3];
  
  /// Site port mappings
  static const Map<String, int> sitePorts = {
    'coordinator': 8080,
    siteQ1: 8081,
    siteQ3: 8083,
  };
}
