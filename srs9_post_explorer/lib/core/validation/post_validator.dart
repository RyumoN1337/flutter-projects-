/// Shared rules for the creation form and repository. Length is measured after trim.
abstract final class PostValidator {
  static String? title(String? value) => _length(value, 5, 100);
  static String? body(String? value) => _length(value, 10, 1000);
  static String? author(int? value) =>
      value == null || value <= 0 ? 'Выберите автора' : null;

  static String? _length(String? value, int min, int max) {
    final length = value?.trim().length ?? 0;
    return length < min || length > max
        ? 'Введите от $min до $max символов'
        : null;
  }
}
