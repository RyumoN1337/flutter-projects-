import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PostCache {
  final SharedPreferences prefs;
  PostCache(this.prefs);
  dynamic read(String key) {
    try {
      final value = prefs.getString('post_explorer_v1_$key');
      return value == null ? null : jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object value) async {
    final saved = await prefs.setString(
      'post_explorer_v1_$key',
      jsonEncode(value),
    );
    if (!saved) throw StateError('Cache write failed');
  }
}
