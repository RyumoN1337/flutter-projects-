import 'package:firebase_database/firebase_database.dart';

/// Сохранение пользователей в Firebase Realtime Database.
class UserRepository {
  final DatabaseReference _users = FirebaseDatabase.instance.ref('users');

  /// Возвращает ключ созданной записи.
  Future<String> saveUser({
    required String name,
    required String email,
    required String phone,
    String? fcmToken,
  }) async {
    final ref = _users.push(); // уникальный id
    await ref.set({
      'name': name,
      'email': email,
      'phone': phone,
      'fcmToken': fcmToken,
      'createdAt': ServerValue.timestamp,
    });
    return ref.key!;
  }
}
