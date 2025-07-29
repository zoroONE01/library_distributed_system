import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

@JsonSerializable()
class UserInfoModel {
  final String username;
  final String email;
  final String fullName;

  const UserInfoModel({
    required this.username,
    required this.email,
    required this.fullName,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) =>
      _$UserInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoModelToJson(this);

  UserInfoModel copyWith({String? username, String? email, String? fullName}) {
    return UserInfoModel(
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
    );
  }

  @override
  String toString() {
    return 'UserInfoModel{username: $username, email: $email, fullName: $fullName}';
  }
}
