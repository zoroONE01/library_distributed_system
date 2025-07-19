import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/widgets/app_button.dart';
import 'package:library_distributed_app/presentation/widgets/app_scaffold.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Column(
          spacing: 10,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: context.primaryColor,
                ),
                Text('Quản lý Thư viện', style: context.headlineLarge),
              ],
            ),
            Text('Đăng nhập để truy cập hệ thống', style: context.headlineSmall),
            LoginForm(),
          ],
        ).wrapByCard(context, width: 420, padding: EdgeInsets.all(40)),
      ),
    );
  }
}

class LoginForm extends ConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      child: Column(
        spacing: 20,
        children: [
          AppTextField(
            context,
            labelText: 'Tên đăng nhập',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
          AppTextField(
            context,
            labelText: 'Mật khẩu',
            obscureText: true,
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
          ),
          AppButton(
            label: 'Đăng nhập',
            width: double.infinity,
            icon: Icon(Icons.login_rounded),
            onPressed: () {
              ref
                  .read(authProvider.notifier)
                  .login(username: 'testuser', password: 'password');
            },
          ),
        ],
      ),
    );
  }
}
