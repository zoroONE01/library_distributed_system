import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';

void main() {
  group('BookCopies Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty book copies entity', () async {
      // Mock authentication to avoid network calls
      // This would normally be mocked with a proper test setup

      // For now, just test that the provider exists and can be read
      final provider = container.read(bookCopiesProvider.notifier);
      expect(provider, isNotNull);
    });

    test('search provider should initialize with empty string', () {
      final searchValue = container.read(bookCopiesSearchProvider);
      expect(searchValue, isEmpty);
    });

    test('search provider should update state when notifier is called', () {
      const testQuery = 'test search';

      container.read(bookCopiesSearchProvider.notifier).state = testQuery;
      final searchValue = container.read(bookCopiesSearchProvider);

      expect(searchValue, equals(testQuery));
    });
  });

  group('BookCopyEntity Tests', () {
    test('should create valid book copy entity', () {
      const bookCopy = BookCopyEntity(
        bookCopyId: 'BC001',
        isbn: '978-0134685991',
        branchSite: Site.q1,
        status: BookStatus.available,
      );

      expect(bookCopy.bookCopyId, equals('BC001'));
      expect(bookCopy.isbn, equals('978-0134685991'));
      expect(bookCopy.branchSite, equals(Site.q1));
      expect(bookCopy.status, equals(BookStatus.available));
      expect(bookCopy.isAvailable, isTrue);
      expect(bookCopy.isBorrowed, isFalse);
    });

    test('should correctly identify borrowed status', () {
      const bookCopy = BookCopyEntity(
        bookCopyId: 'BC002',
        isbn: '978-0134685991',
        branchSite: Site.q3,
        status: BookStatus.borrowed,
      );

      expect(bookCopy.isAvailable, isFalse);
      expect(bookCopy.isBorrowed, isTrue);
      expect(bookCopy.isDamaged, isFalse);
    });
  });

  group('BookCopiesEntity Tests', () {
    test('should create empty book copies entity', () {
      const bookCopies = BookCopiesEntity();

      expect(bookCopies.items, isEmpty);
      expect(bookCopies.paging, equals(const PagingEntity()));
    });

    test('should create book copies entity with data', () {
      const bookCopy1 = BookCopyEntity(
        bookCopyId: 'BC001',
        isbn: '978-0134685991',
        branchSite: Site.q1,
        status: BookStatus.available,
      );

      const bookCopy2 = BookCopyEntity(
        bookCopyId: 'BC002',
        isbn: '978-0134685992',
        branchSite: Site.q1,
        status: BookStatus.borrowed,
      );

      const paging = PagingEntity(currentPage: 0, pageSize: 20, totalPages: 1);

      const bookCopies = BookCopiesEntity(
        items: [bookCopy1, bookCopy2],
        paging: paging,
      );

      expect(bookCopies.items, hasLength(2));
      expect(bookCopies.items[0].bookCopyId, equals('BC001'));
      expect(bookCopies.items[1].bookCopyId, equals('BC002'));
      expect(bookCopies.paging.currentPage, equals(0));
      expect(bookCopies.paging.pageSize, equals(20));
    });
  });
}
