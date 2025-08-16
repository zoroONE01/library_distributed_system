import 'package:json_annotation/json_annotation.dart';

part 'login_form.g.dart';

@JsonSerializable()
class LoginFormModel {
  final String username;
  final String password;

  const LoginFormModel({required this.username, required this.password});

  factory LoginFormModel.fromJson(Map<String, dynamic> json) =>
      _$LoginFormModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginFormModelToJson(this);
}
