import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/readers/providers/readers_provider.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

class ReaderListCreateDialog extends ConsumerStatefulWidget {
  const ReaderListCreateDialog({
    super.key,
  });

  @override
  ConsumerState<ReaderListCreateDialog> createState() => _ReaderListCreateDialogState();
}

class _ReaderListCreateDialogState extends ConsumerState<ReaderListCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _readerIdController = TextEditingController();
  final _fullNameController = TextEditingController();

  @override
  void dispose() {
    _readerIdController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm độc giả mới'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                context,
                controller: _readerIdController,
                labelText: 'Mã độc giả *',
                prefixIcon: const Icon(Icons.badge_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã độc giả';
                  }
                  if (value.trim().length < 3) {
                    return 'Mã độc giả phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                context,
                controller: _fullNameController,
                labelText: 'Họ và tên *',
                prefixIcon: const Icon(Icons.person_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  if (value.trim().length < 2) {
                    return 'Họ và tên phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final currentSite = ref.watch(librarySiteProvider);
                  return TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh đăng ký',
                      prefixIcon: Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: 'Chi nhánh ${currentSite.text}',
                    enabled: false, // Automatically assigned to librarian's site
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Lưu ý: Chi nhánh đăng ký sẽ được tự động gán theo chi nhánh của thủ thư',
                style: context.bodySmall.copyWith(
                  color: context.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: context.maybePop,
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: _handleSubmit,
          child: Text(
            'Thêm',
            style: context.bodyLarge.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Get current site for registration (FR8: THUTHU can only create at their site)
      final currentSite = ref.read(librarySiteProvider);
      
      final reader = ReaderEntity(
        readerId: _readerIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        registrationSite: currentSite,
      );

      await ref.read(createReaderProvider(reader).future);

      if (mounted) {
        context.maybePop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm độc giả mới thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm độc giả: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }
}
