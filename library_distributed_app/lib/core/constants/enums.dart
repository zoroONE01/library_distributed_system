import 'package:json_annotation/json_annotation.dart';

enum Site {
  @JsonValue('Q1')
  q1('Quận 1'),
  @JsonValue('Q3')
  q3('Quận 3');

  final String text;
  const Site(this.text);

  static Site fromString(String? value) {
    switch (value) {
      case 'Q1':
        return Site.q1;
      case 'Q3':
        return Site.q3;
      default:
        return Site.q1;
    }
  }
}

enum UserRole {
  @JsonValue('THUTHU')
  librarian('Thủ Thư'),
  @JsonValue('QUANLY')
  manager('Quản Lý');

  final String text;
  const UserRole(this.text);
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
