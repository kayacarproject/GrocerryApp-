/// Form validators returning a user-facing message, or `null` when valid.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _phone = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _pincode = RegExp(r'^[1-9]\d{5}$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  static String? required(String? value, [String field = 'This field']) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? name(String? value) {
    final error = required(value, 'Name');
    if (error != null) return error;
    return value!.trim().length < 2 ? 'Enter a valid name' : null;
  }

  static String? email(String? value) {
    final error = required(value, 'Email');
    if (error != null) return error;
    return isEmail(value!) ? null : 'Enter a valid email';
  }

  static String? phone(String? value) {
    final error = required(value, 'Phone number');
    if (error != null) return error;
    return _phone.hasMatch(value!.trim())
        ? null
        : 'Enter a valid 10-digit mobile number';
  }

  static String? emailOrPhone(String? value) {
    final error = required(value, 'Email or phone');
    if (error != null) return error;
    final text = value!.trim();
    return (_email.hasMatch(text) || _phone.hasMatch(text))
        ? null
        : 'Enter a valid email or 10-digit mobile number';
  }

  static String? password(String? value) {
    final error = required(value, 'Password');
    if (error != null) return error;
    if (value!.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? loginPassword(String? value) => required(value, 'Password');

  static String? Function(String?) confirmPassword(
    String Function() original,
  ) => (value) {
    final error = required(value, 'Confirm password');
    if (error != null) return error;
    return value == original() ? null : 'Passwords do not match';
  };

  static String? pincode(String? value) {
    final error = required(value, 'Pincode');
    if (error != null) return error;
    return _pincode.hasMatch(value!.trim()) ? null : 'Enter a valid pincode';
  }
}
