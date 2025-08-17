import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';
import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/book_transfer/providers/book_transfer_provider.dart';

/// Dialog for transferring book copies between sites
/// Only available for QUANLY (Manager) role
/// Implements distributed transaction using 2PC protocol
class BookTransferDialog extends ConsumerStatefulWidget {
  const BookTransferDialog({super.key});

  @override
  ConsumerState<BookTransferDialog> createState() => _BookTransferDialogState();
}

class _BookTransferDialogState extends ConsumerState<BookTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bookCopyIdController = TextEditingController();
  final _searchController = TextEditingController();

  Site? _selectedFromSite;
  Site? _selectedToSite;
  BookCopyTransferInfoEntity? _selectedBookCopy;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Set default from site to current site
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSite = ref.read(librarySiteProvider);
      setState(() {
        _selectedFromSite = currentSite;
      });
    });
  }

  @override
  void dispose() {
    _bookCopyIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.transfer_within_a_station_rounded,
            color: context.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Chuyển sách giữa các chi nhánh',
            style: context.titleLarge.bold,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tính năng này sử dụng giao thức Two-Phase Commit (2PC) để đảm bảo tính nhất quán dữ liệu trong hệ thống phân tán.',
                  style: context.bodyMedium.copyWith(
                    color: context.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBookSearchSection(),
                if (_selectedBookCopy != null) ...[
                  const SizedBox(height: 20),
                  _buildSelectedBookInfo(),
                ],
                const SizedBox(height: 20),
                _buildSiteSelection(),
                const SizedBox(height: 24),
                _buildTransferInfo(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy',
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: context.surfaceContainer,
          shadowColor: Colors.transparent,
        ),
        AppButton(
          label: _isLoading ? 'Đang chuyển...' : 'Chuyển sách',
          onPressed: _canTransfer() ? _handleTransfer : null,
          backgroundColor: context.primaryColor,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 16),
        ),
      ],
    );
  }

  Widget _buildBookSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tìm kiếm quyển sách cần chuyển', style: context.titleMedium.bold),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      context,
                      controller: _searchController,
                      labelText:
                          'Tìm kiếm theo mã sách, tên sách, hoặc tác giả',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      onChanged: (value) => _performSearch(value),
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Hoặc nhập mã',
              onPressed: () => _showBookCopyIdInput(),
              backgroundColor: context.surfaceContainer,
              shadowColor: Colors.transparent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchResults(),
      ],
    );
  }

  Widget _buildSearchResults() {
    final transferableBookCopiesAsync = ref.watch(
      transferableBookCopiesProvider,
    );

    return transferableBookCopiesAsync.when(
      data: (bookCopies) {
        if (bookCopies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nhập từ khóa để tìm kiếm sách có sẵn',
                  style: context.bodyMedium.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: context.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: bookCopies.length,
            itemBuilder: (context, index) {
              final bookCopy = bookCopies[index];
              final isSelected =
                  _selectedBookCopy?.bookCopyId == bookCopy.bookCopyId;

              return ListTile(
                selected: isSelected,
                selectedColor: context.onPrimaryContainer,
                selectedTileColor: context.primaryContainer,
                leading: Icon(
                  Icons.book_rounded,
                  color: isSelected
                      ? context.onPrimaryContainer
                      : context.onSurface,
                ),
                title: Text(
                  bookCopy.bookTitle,
                  style: context.bodyLarge.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tác giả: ${bookCopy.authorName}'),
                    Text(
                      'Mã sách: ${bookCopy.bookCopyId} • Chi nhánh: ${bookCopy.currentSite.text}',
                    ),
                  ],
                ),
                trailing: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? context.primaryColor
                      : context.onSurfaceVariant,
                ),
                onTap: () {
                  setState(() {
                    _selectedBookCopy = bookCopy;
                    _selectedFromSite = bookCopy.currentSite;
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lỗi tìm kiếm: $error',
                style: context.bodyMedium.copyWith(
                  color: context.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBookInfo() {
    if (_selectedBookCopy == null) return const SizedBox.shrink();

    final bookCopy = _selectedBookCopy!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: context.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sách đã chọn',
                style: context.titleSmall.bold.copyWith(
                  color: context.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bookCopy.bookTitle,
            style: context.bodyLarge.bold.copyWith(
              color: context.onPrimaryContainer,
            ),
          ),
          Text(
            'Tác giả: ${bookCopy.authorName}',
            style: context.bodyMedium.copyWith(
              color: context.onPrimaryContainer,
            ),
          ),
          Text(
            'Mã sách: ${bookCopy.bookCopyId}',
            style: context.bodyMedium.copyWith(
              color: context.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn chi nhánh chuyển', style: context.titleMedium.bold),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Từ chi nhánh',
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Site>(
                    value: _selectedFromSite,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabled: _selectedBookCopy == null,
                    ),
                    items: Site.values.map((site) {
                      return DropdownMenuItem(
                        value: site,
                        child: Text(site.text),
                      );
                    }).toList(),
                    onChanged: _selectedBookCopy == null
                        ? (Site? value) {
                            setState(() {
                              _selectedFromSite = value;
                            });
                          }
                        : null,
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn chi nhánh nguồn';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: context.primaryColor,
                size: 32,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đến chi nhánh',
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Site>(
                    value: _selectedToSite,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: Site.values
                        .where((site) => site != _selectedFromSite)
                        .map((site) {
                          return DropdownMenuItem(
                            value: site,
                            child: Text(site.text),
                          );
                        })
                        .toList(),
                    onChanged: (Site? value) {
                      setState(() {
                        _selectedToSite = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn chi nhánh đích';
                      }
                      if (value == _selectedFromSite) {
                        return 'Chi nhánh đích phải khác chi nhánh nguồn';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransferInfo() {
    if (!_canTransfer()) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: context.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Thông tin chuyển sách', style: context.titleSmall.bold),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sách "${_selectedBookCopy?.bookTitle}" sẽ được chuyển từ ${_selectedFromSite?.text} đến ${_selectedToSite?.text}.',
            style: context.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '• Giao dịch sử dụng giao thức Two-Phase Commit (2PC)',
            style: context.bodySmall.copyWith(color: context.onSurfaceVariant),
          ),
          Text(
            '• Dữ liệu sẽ được cập nhật đồng bộ trên cả hai chi nhánh',
            style: context.bodySmall.copyWith(color: context.onSurfaceVariant),
          ),
          Text(
            '• Quyển sách sẽ bị xóa khỏi chi nhánh nguồn và thêm vào chi nhánh đích',
            style: context.bodySmall.copyWith(color: context.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      ref.read(transferableBookCopiesProvider.notifier).clear();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      await ref
          .read(transferableBookCopiesProvider.notifier)
          .search(query.trim());
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showBookCopyIdInput() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã quyển sách'),
        content: AppTextField(
          context,
          controller: _bookCopyIdController,
          labelText: 'Mã quyển sách',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (_bookCopyIdController.text.isNotEmpty) {
                _lookupBookCopy(_bookCopyIdController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  void _lookupBookCopy(String bookCopyId) async {
    try {
      setState(() {
        _isSearching = true;
      });

      final bookCopy = await ref.read(
        bookCopyTransferInfoProvider(bookCopyId).future,
      );

      setState(() {
        _selectedBookCopy = bookCopy;
        _selectedFromSite = bookCopy.currentSite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy quyển sách: $e'),
            backgroundColor: context.errorContainer,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  bool _canTransfer() {
    return _selectedBookCopy != null &&
        _selectedFromSite != null &&
        _selectedToSite != null &&
        _selectedFromSite != _selectedToSite &&
        !_isLoading;
  }

  void _handleTransfer() async {
    if (!_formKey.currentState!.validate() || !_canTransfer()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = BookTransferRequestEntity(
        bookCopyId: _selectedBookCopy!.bookCopyId,
        fromSite: _selectedFromSite!,
        toSite: _selectedToSite!,
      );

      await ref.read(transferBookCopyProvider(request).future);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chuyển sách "${_selectedBookCopy!.bookTitle}" từ ${_selectedFromSite!.text} đến ${_selectedToSite!.text} thành công!',
            ),
            backgroundColor: context.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chuyển sách: $e'),
            backgroundColor: context.errorContainer,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
