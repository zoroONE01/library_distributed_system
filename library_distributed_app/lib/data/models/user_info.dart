import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';

part 'user_info.g.dart';

@JsonSerializable()
class UserInfoModel {
  final String id;
  final String username;
  final UserRole role;

  @JsonKey(name: 'maCN')
  final Site site;

  UserInfoModel({
    required this.id,
    required this.username,
    required this.role,
    required this.site,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) =>
      _$UserInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {id: $id, username: $username, role: $role, site: ${site.name}';
  }

  UserInfoEntity toEntity() {
    return UserInfoEntity(id: id, username: username, role: role);
  }
}
