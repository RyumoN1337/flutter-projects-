import 'package:shared_preferences/shared_preferences.dart';

/// Данные пользователя, которые сохраняются локально.
///
/// Пароль намеренно НЕ сохраняется: SharedPreferences хранит данные
/// в открытом виде. Для секретов в реальных проектах используют
/// flutter_secure_storage.
class UserData {
  final String name;
  final String phone;
  final String email;
  final String story;

  const UserData({
    required this.name,
    required this.phone,
    required this.email,
    required this.story,
  });
}

/// Обёртка над SharedPreferences: сохранить / прочитать / удалить.
class UserStorage {
  static const _kName = 'user_name';
  static const _kPhone = 'user_phone';
  static const _kEmail = 'user_email';
  static const _kStory = 'user_story';

  static Future<void> save(UserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, data.name);
    await prefs.setString(_kPhone, data.phone);
    await prefs.setString(_kEmail, data.email);
    await prefs.setString(_kStory, data.story);
  }

  /// Возвращает сохранённые данные или null, если их ещё нет.
  static Future<UserData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kName);
    if (name == null) return null;
    return UserData(
      name: name,
      phone: prefs.getString(_kPhone) ?? '',
      email: prefs.getString(_kEmail) ?? '',
      story: prefs.getString(_kStory) ?? '',
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kPhone);
    await prefs.remove(_kEmail);
    await prefs.remove(_kStory);
  }
}
