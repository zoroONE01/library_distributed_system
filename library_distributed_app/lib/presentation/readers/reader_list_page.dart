import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/readers/providers/readers_provider.dart';
import 'package:library_distributed_app/presentation/readers/reader_list_create_dialog.dart';
import 'package:library_distributed_app/presentation/readers/widgets/readers_table.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

class ReaderListPage extends ConsumerStatefulWidget {
  const ReaderListPage({super.key});

  @override
  ConsumerState<ReaderListPage> createState() => _ReaderListPageState();
}

class _ReaderListPageState extends ConsumerState<ReaderListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(getUserInfoProvider);

    return userInfoAsync.when(
      data: (userInfo) => _buildPage(context, userInfo),
      loading: () => const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => AppScaffold(
        body: Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  Widget _buildPage(BuildContext context, UserInfoEntity userInfo) {
    return AppScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(context, userInfo),
          _buildContent(context, userInfo),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserInfoEntity userInfo) {
    return Consumer(
      builder: (context, ref, child) {
        final site = ref.watch(librarySiteProvider);
        final siteName = userInfo.role == UserRole.manager 
            ? 'Toàn hệ thống'
            : 'Chi nhánh ${site.text}';
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Expanded(
              child: Text(
                'Danh sách độc giả - $siteName',
                style: context.headlineSmall.bold,
                overflow: TextOverflow.ellipsis,
              ).withIcon(Icons.people_rounded, iconColor: context.primaryColor),
            ),
            // Only THUTHU can create readers at their site (FR8)
            if (userInfo.role == UserRole.librarian)
              AppButton(
                label: 'Thêm độc giả mới',
                icon: const Icon(Icons.person_add_rounded, size: 20),
                onPressed: () => _showCreateDialog(context),
                backgroundColor: context.primaryColor,
              ),
          ],
        ).wrapByCard(context);
      },
    );
  }

  Widget _buildContent(BuildContext context, UserInfoEntity userInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 20,
      children: [
        _buildSearchRow(context),
        const ReadersTable(),
      ],
    ).wrapByCard(context);
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  context,
                  controller: _searchController,
                  labelText: 'Tìm kiếm độc giả (theo tên hoặc mã)',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        ref.read(readersSearchProvider.notifier).state = value;
                        ref.read(readersProvider.notifier).fetchData(0, value.isEmpty ? null : value);
                      }
                    });
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(readersSearchProvider.notifier).state = '';
                    ref.read(readersProvider.notifier).fetchData(0, null);
                  },
                ),
              ],
            ],
          ),
        ),
        AppButton(
          label: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => ref.read(readersProvider.notifier).refresh(),
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    const ReaderListCreateDialog().showAsDialog(context).then((result) {
      if (result != null) {
        // Refresh the list after creation
        ref.read(readersProvider.notifier).refresh();
      }
    });
  }
}
