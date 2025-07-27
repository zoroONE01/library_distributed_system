import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'login_form.g.dart';

@JsonSerializable()
class LoginFormEntity {
  final String username;
  final String password;

  const LoginFormEntity({required this.username, required this.password});

  factory LoginFormEntity.fromJson(Map<String, dynamic> json) =>
      _$LoginFormEntityFromJson(json);

  Map<String, dynamic> toJson() => _$LoginFormEntityToJson(this);

  LoginFormEntity copyWith({String? username, String? password, Site? site}) {
    return LoginFormEntity(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
