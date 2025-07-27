enum Site {
  q1,
  q3;

  static Site fromString(String? value) {
    switch (value) {
      case 'q1':
        return Site.q1;
      case 'q3':
        return Site.q3;
      default:
        return Site.q1;
    }
  }
}

enum UserRole { librarian, manager }

enum BookSortOption { name, author, category, quantity }

enum SortOrder { ascending, descending }
