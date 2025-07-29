import 'package:json_annotation/json_annotation.dart';

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

enum UserRole {
  @JsonValue('THUTHU')
  librarian,
  @JsonValue('QUANLY')
  manager,
}

enum UserRolePermission {
  @JsonValue('BRANCH_ACCESS')
  branchAccess,
  @JsonValue('BOOK_BORROW')
  bookBorrow,
  @JsonValue('BOOK_RETURN')
  bookReturn,
  @JsonValue('BOOK_MANAGE')
  bookManage,
  @JsonValue('USER_MANAGE')
  userManage,
  @JsonValue('REPORT_VIEW')
  reportView,
}

enum BookSortOption { name, author, category, quantity }

enum SortOrder { ascending, descending }
