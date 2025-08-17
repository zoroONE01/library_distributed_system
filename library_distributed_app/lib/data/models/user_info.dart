import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';

part 'user_info.g.dart';

@JsonSerializable()
class UserInfoModel {
  final String id;
  final String username;
  final UserRole role;

  @JsonKey(name: 'maCN', fromJson: _siteFromJson)
  final Site? site;

  final String? permissions;

  const UserInfoModel({
    this.id = '',
    this.username = '',
    this.role = UserRole.librarian,
    this.site,
    this.permissions,
  });

  static Site? _siteFromJson(dynamic value) {
    if (value == null || value == '') {
      // For managers (QUANLY) who don't have a specific site
      return null;
    }
    return Site.fromString(value.toString());
  }

  factory UserInfoModel.fromJson(Map<String, dynamic> json) =>
      _$UserInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {id: $id, username: $username, role: $role, site: ${site?.name}, permissions: $permissions';
  }

  UserInfoEntity toEntity() {
    return UserInfoEntity(id: id, username: username, role: role);
  }
}
