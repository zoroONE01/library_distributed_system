import 'package:library_distributed_app/core/constants/enums.dart';

class UserInfoEntity {
  final String id;
  final String username;
  final UserRole role;

  const UserInfoEntity({
    required this.id,
    required this.username,
    required this.role,
  });
}
