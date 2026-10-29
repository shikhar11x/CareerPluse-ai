abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) =>
      _email.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address';

  static String? password(String? v) =>
      (v ?? '').length >= 8 ? null : 'Use at least 8 characters';

  static String? Function(String?) required(String label) =>
      (v) => (v ?? '').trim().isEmpty ? 'Enter your $label' : null;
}