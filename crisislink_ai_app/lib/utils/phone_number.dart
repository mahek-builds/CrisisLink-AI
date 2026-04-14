String normalizePhoneNumber(String input) {
  final trimmed = input.trim();
  final hasLeadingPlus = trimmed.startsWith('+');
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

  if (digitsOnly.isEmpty) {
    return '';
  }

  return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
}

String? validatePhoneNumber(String input) {
  final normalized = normalizePhoneNumber(input);
  if (normalized.isEmpty) {
    return 'Phone number is required to continue.';
  }

  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(normalized)) {
    return 'Enter a valid phone number to continue.';
  }

  return null;
}
