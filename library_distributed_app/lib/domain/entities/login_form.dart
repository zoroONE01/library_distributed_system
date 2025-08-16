class LoginFormEntity {
  final String username;
  final String password;

  const LoginFormEntity({this.username = '', this.password = ''});

  Map<String, String> toJson() {
    return {'username': username, 'password': password};
  }
}
