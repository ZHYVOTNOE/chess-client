class ProfileValidator {
  static String? nickname(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите никнейм';
    }
    if (value.length < 3) {
      return 'Минимум 3 символа';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Только буквы, цифры и "_"';
    }
    return null;
  }
}