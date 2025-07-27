class AppValidator {
  const AppValidator._();

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username không được để trống';
    }
    if (value.length < 2) {
      return 'Username phải có ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password không được để trống';
    }
    if (value.length < 6) {
      return 'Password phải có ít nhất 6 ký tự';
    }

    return null;
  }
}
