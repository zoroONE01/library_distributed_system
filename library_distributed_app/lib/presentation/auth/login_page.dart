import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/toast_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/core/utils/validator.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_drop_down_button.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

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
            Text(
              'Đăng nhập để truy cập hệ thống',
              style: context.headlineSmall,
            ),
            const LoginForm(),
          ],
        ).wrapByCard(context, width: 420, padding: const EdgeInsets.all(40)),
      ),
    );
  }
}

class LoginForm extends HookConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new, const []);
    final usernameController = useTextEditingController(text: 'ThuThu_Q1');
    final passwordController = useTextEditingController(text: 'ThuThu123@');

    ref.listen(authProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          context.showError(error.toString());
        },
      );
    });

    return Form(
      key: formKey,
      child: Column(
        spacing: 20,
        children: [
          AppTextField(
            context,
            labelText: 'Tên đăng nhập',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            validator: AppValidator.validateUsername,
            controller: usernameController,
          ),
          AppTextField(
            context,
            labelText: 'Mật khẩu',
            obscureText: true,
            controller: passwordController,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            validator: AppValidator.validatePassword,
          ),
          Consumer(
            child: Text('Chi nhánh:', style: context.bodyLarge.bold),
            builder: (context, ref, child) {
              final site = ref.watch(librarySiteProvider);
              return Row(
                spacing: 10,
                children: [
                  child!,
                  Expanded(
                    child: AppDropDownButton<Site>(
                      items: Site.values
                          .map(
                            (site) => AppDropDownItem<Site>(
                              value: site,
                              label: switch (site) {
                                Site.q1 => 'Quận 1',
                                Site.q3 => 'Quận 3',
                              },
                            ),
                          )
                          .toList(),
                      value: site,
                      onChanged: ref.read(librarySiteProvider.notifier).setSite,
                    ),
                  ),
                ],
              );
            },
          ),
          AppButton(
            label: 'Đăng nhập',
            width: double.infinity,
            icon: const Icon(Icons.login_rounded),
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              ref
                  .read(authProvider.notifier)
                  .login(
                    username: usernameController.text,
                    password: passwordController.text,
                  );
            },
          ),
        ],
      ),
    );
  }
}
