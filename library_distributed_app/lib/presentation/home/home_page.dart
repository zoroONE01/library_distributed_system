import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/core/theme/app_theme_mode.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/widgets/app_button.dart';
import 'package:library_distributed_app/presentation/widgets/app_scaffold.dart';
import 'package:library_distributed_app/presentation/widgets/app_table.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';
import 'package:library_distributed_app/presentation/widgets/board_layout.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: context.primaryColor),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thư viện Quận 1',
                    style: context.headlineMedium.copyWith(
                      color: context.onPrimary,
                    ),
                  ),
                  Text(
                    'Thủ thư: Nguyễn Văn A',
                    style: context.bodyLarge.copyWith(color: context.onPrimary),
                  ),
                  Text(
                    'Vai trò: THUTHU',
                    style: context.bodyLarge.copyWith(color: context.onPrimary),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: context.onSurface),
              title: Text('Cài đặt', style: context.bodyLarge),
              onTap: () {},
            ),
            Consumer(
              builder: (context, ref, child) {
                final themeMode = ref.watch(appThemeModeProvider);
                return ListTile(
                  leading: Icon(switch (themeMode) {
                    ThemeMode.light => Icons.light_mode,
                    ThemeMode.dark => Icons.dark_mode,
                    ThemeMode.system => Icons.brightness_auto,
                  }, color: context.onSurface),
                  title: Text(
                    'Theme: ${themeMode.name.toUpperCase()}',
                    style: context.bodyLarge,
                  ),
                  onTap: () {
                    ref.read(appThemeModeProvider.notifier).toggleBrightness();
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: context.onSurface),
              title: Text('Đăng xuất', style: context.bodyLarge),
              onTap: () {
                showAdaptiveDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Xác nhận đăng xuất'),
                      content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Hủy', style: context.bodyLarge),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ref.read(authProvider.notifier).logout();
                          },
                          child: Text('Đăng xuất', style: context.bodyLarge),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: BoardLayout(
        sideBar: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Text(
                  'Quản lý Độc giả',
                  style: context.headlineSmall.bold,
                ).withIcon(Icons.people_alt_outlined),
                AppButton(
                  label: 'Thêm Độc giả mới',
                  onPressed: () {
                    showAdaptiveDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Thêm Độc giả mới'),
                          content: AppTextField(
                            context,
                            labelText: 'Nhập tên độc giả',
                            prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Hủy', style: context.bodyLarge),
                            ),
                            TextButton(
                              onPressed: Navigator.of(context).pop,
                              child: Text('Thêm', style: context.bodyLarge),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  backgroundColor: context.onSurface.withValues(alpha: 0.2),
                  shadowColor: Colors.transparent,
                ),
              ],
            ).wrapByCard(
              context,
              backgroundColor: context.primaryColor,
              width: double.infinity,
            ),
            Text(
              'Tra cứu',
              style: context.headlineSmall.bold,
            ).withIcon(Icons.search_rounded),
            AppTextField(
              context,
              onTap: () {
                showAdaptiveDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: AppTextField(
                        context,
                        labelText: 'Nhập từ khóa tìm kiếm',
                        prefixIcon: Icon(Icons.search),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Hủy', style: context.bodyLarge),
                        ),
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: Text('Tìm kiếm', style: context.bodyLarge),
                        ),
                      ],
                    );
                  },
                );
              },
              labelText: 'Tìm sách, độc giả tại chi nhánh...',
            ),
            AppButton(
              label: 'Tìm kiếm',
              onPressed: () {},
              width: double.infinity,
              backgroundColor: context.onSurface.withValues(alpha: 0.2),
              shadowColor: Colors.transparent,
            ),
          ],
        ).wrapByCard(context),
        mainContent: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Expanded(
                  child:
                      Text(
                        'Thư viện chi nhánh Quận 1',
                        style: context.headlineSmall.bold,
                        overflow: TextOverflow.ellipsis,
                      ).withIcon(
                        Icons.location_city_rounded,
                        iconColor: context.primaryColor,
                      ),
                ),
                Builder(
                  builder: (context) {
                    return CupertinoButton(
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      padding: EdgeInsets.zero,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          border: Border(
                            right: BorderSide(
                              color: context.colorScheme.outline,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            border: Border(
                              right: BorderSide(
                                color: context.colorScheme.outline.withValues(
                                  alpha: 0.4,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Thủ thư: Nguyễn Văn A',
                                style: context.bodyMedium.bold,
                              ),
                              Text(
                                'Vai trò: THUTHU',
                                style: context.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ).wrapByCard(context),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                Text(
                  'Thao tác mượn/trả',
                  style: context.headlineSmall.bold,
                ).withIcon(Icons.stacked_bar_chart_rounded),
                Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lập phiếu mượn sách',
                            style: context.bodyMedium.bold,
                          ),
                          AppTextField(
                            context,
                            labelText: 'Nhập mã độc giả (Ví dụ: 12345)',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                          ),
                          AppTextField(
                            context,
                            labelText: 'Nhập mã sách (Ví dụ: 67890)',
                            prefixIcon: Icon(Icons.book_sharp, size: 20),
                          ),
                          AppButton(
                            label: 'Tạo phiếu mượn',
                            onPressed: () {},
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi nhận trả sách',
                            style: context.bodyMedium.bold,
                          ),
                          AppTextField(
                            context,
                            labelText: 'Nhập mã phiếu mượn (Ví dụ: 67890)',
                            prefixIcon: Icon(Icons.book_sharp, size: 20),
                          ),
                          AppButton(
                            label: 'Xác nhận trả',
                            onPressed: () {},
                            width: double.infinity,
                            backgroundColor: context.onSurface.withValues(
                              alpha: 0.2,
                            ),
                            shadowColor: Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ).wrapByCard(context),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child:
                      Text(
                        'Cảnh báo Sách Quá hạn',
                        style: context.headlineSmall.bold,
                      ).withIcon(
                        Icons.info_outlined,
                        iconColor: context.headlineSmall.color,
                      ),
                  onPressed: () {},
                ),
                AppTable.build(
                  context,
                  columnWidths: const [1, 1, 1, 1, 1],
                  titles: [
                    'Mã sách',
                    'Tên sách',
                    'Mã đọc giả',
                    'Ngày mượn',
                    'Tình trạng',
                  ],
                ),
              ],
            ).wrapByCard(context),
          ],
        ),
      ),
    );
  }
}
