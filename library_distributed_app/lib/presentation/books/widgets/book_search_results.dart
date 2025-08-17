import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';

/// Book Search Results Widget - FR7 Implementation
/// Displays system-wide search results across all branches
/// Shows books with their availability information per branch
class BookSearchResults extends ConsumerWidget {
  const BookSearchResults({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(
      searchBooksSystemWideProvider(searchQuery),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả tìm kiếm cho: "$searchQuery"',
          style: context.headlineMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: searchResultsAsync.whenDataOrPreviousWidget((searchResults) {
            if (searchResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: context.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy sách nào với từ khóa "$searchQuery"',
                      style: context.bodyLarge.copyWith(
                        color: context.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return _buildSearchResultsTable(context, searchResults);
          }),
        ),
      ],
    );
  }

  Widget _buildSearchResultsTable(
    BuildContext context,
    List<BookSearchResultEntity> searchResults,
  ) {
    return AppTable.build(
      context,
      columnWidths: const [1, 2, 4, 3, 2, 3],
      titles: const [
        '#',
        'Mã ISBN',
        'Tên sách',
        'Tác giả',
        'Số lượng',
        'Chi nhánh có sẵn',
      ],
      rows: searchResults
          .asMap()
          .entries
          .map(
            (entry) => _buildSearchResultRow(
              context,
              index: entry.key,
              searchResult: entry.value,
            ),
          )
          .toList(),
    );
  }

  TableRow _buildSearchResultRow(
    BuildContext context, {
    required int index,
    required BookSearchResultEntity searchResult,
  }) {
    final book = searchResult.book;
    final availableBranches = searchResult.availableBranches;
    final availableCount = searchResult.availableCount;

    return TableRow(
      children: [
        AppTable.buildTextCell(context, text: (index + 1).toString()),
        AppTable.buildTextCell(context, text: book.isbn),
        AppTable.buildTextCell(context, text: book.title),
        AppTable.buildTextCell(context, text: book.author),
        AppTable.buildWidgetCell(
          context,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                availableCount > 0 ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: availableCount > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                availableCount.toString(),
                style: context.bodyMedium.copyWith(
                  color: availableCount > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        AppTable.buildWidgetCell(
          context,
          child: availableBranches.isEmpty
              ? Text(
                  'Không có',
                  style: context.bodySmall.copyWith(
                    color: context.onSurface.withValues(alpha: 0.6),
                  ),
                )
              : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: availableBranches
                      .map(
                        (branch) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            branch.name,
                            style: context.bodySmall.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
