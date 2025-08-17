import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/presentation/readers/providers/readers_provider.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

class ReaderEditDialog extends ConsumerStatefulWidget {
  final ReaderEntity? reader;

  const ReaderEditDialog({
    super.key,
    this.reader,
  });

  @override
  ConsumerState<ReaderEditDialog> createState() => _ReaderEditDialogState();
}

class _ReaderEditDialogState extends ConsumerState<ReaderEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _readerIdController;
  late final TextEditingController _fullNameController;
  late Site _selectedSite;

  bool get _isEditing => widget.reader != null;

  @override
  void initState() {
    super.initState();
    _readerIdController = TextEditingController(text: widget.reader?.readerId ?? '');
    _fullNameController = TextEditingController(text: widget.reader?.fullName ?? '');
    _selectedSite = widget.reader?.registrationSite ?? Site.q1;
  }

  @override
  void dispose() {
    _readerIdController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Chỉnh sửa độc giả' : 'Thêm độc giả mới'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                // Reader ID field - conditional based on editing mode
              _isEditing
                  ? TextFormField(
                      controller: _readerIdController,
                      decoration: const InputDecoration(
                        labelText: 'Mã độc giả',
                        prefixIcon: Icon(Icons.badge_rounded),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false, // Read-only when editing
                    )
                  : AppTextField(
                      context,
                      controller: _readerIdController,
                      labelText: 'Mã độc giả',
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
                labelText: 'Họ và tên',
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
              DropdownButtonFormField<Site>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  labelText: 'Chi nhánh đăng ký',
                  prefixIcon: Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(),
                ),
                items: Site.values.map((site) {
                  return DropdownMenuItem<Site>(
                    value: site,
                    child: Text('Chi nhánh ${site.text}'),
                  );
                }).toList(),
                onChanged: _isEditing 
                    ? null // Cannot change registration site when editing (fragmentation key)
                    : (Site? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSite = value;
                          });
                        }
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn chi nhánh đăng ký';
                  }
                  return null;
                },
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Lưu ý: Không thể thay đổi mã độc giả và chi nhánh đăng ký khi chỉnh sửa',
                    style: context.bodySmall.copyWith(
                      color: context.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
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
            _isEditing ? 'Cập nhật' : 'Thêm',
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
      final reader = ReaderEntity(
        readerId: _readerIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        registrationSite: _selectedSite,
      );

      if (_isEditing) {
        // Update existing reader (FR8)
        await ref.read(updateReaderProvider((
          readerId: widget.reader!.readerId,
          reader: reader,
        )).future);
      } else {
        // Create new reader (FR8)
        await ref.read(createReaderProvider(reader).future);
      }

      if (mounted) {
        context.maybePop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Cập nhật thông tin độc giả thành công'
                  : 'Thêm độc giả mới thành công',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Lỗi khi cập nhật độc giả: $e'
                  : 'Lỗi khi thêm độc giả: $e',
            ),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }
}
