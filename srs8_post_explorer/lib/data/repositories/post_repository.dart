import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/models.dart';
import '../remote/post_api.dart';

class PostRepository {
  final PostApi api;
  final PostCache cache;
  PostRepository(this.api, this.cache);
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, s) {
      if (kDebugMode) debugPrint('$e\n$s');
      if (e is DioException && CancelToken.isCancel(e)) rethrow;
      throw AppException.from(e);
    }
  }

  Future<void> save(String key, Object value) async {
    try {
      await cache.write(key, value);
    } catch (e) {
      if (kDebugMode) debugPrint('Cache: $e');
    }
  }

  T? cached<T>(String key, T Function(dynamic) parse) {
    try {
      final data = cache.read(key);
      return data == null ? null : parse(data);
    } catch (_) {
      return null;
    }
  }

  String feedKey(int? author) => 'feed_${author ?? 'all'}';
  List<Post> cachedPosts(int? author) =>
      cached(
        feedKey(author),
        (j) => (j as List)
            .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      ) ??
      [];
  List<Post> localPosts() =>
      cached(
        'local',
        (j) => (j as List)
            .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      ) ??
      [];
  Future<void> saveFeed(int? author, List<Post> posts) =>
      save(feedKey(author), posts.map((e) => e.toJson()).toList());
  Future<List<Post>> page(int page, int? author, CancelToken token) => guard(
    () => author == null
        ? api.posts(page, 10, token)
        : api.authorPosts(author, page, 10, token),
  );
  Future<Post> post(int id) => guard(() async {
    final p = await api.post(id);
    await save('post_$id', p.toJson());
    return p;
  });
  Future<List<Comment>> comments(int id) => guard(() async {
    final c = await api.comments(id);
    await save('comments_$id', c.map((e) => e.toJson()).toList());
    return c;
  });
  Future<List<User>> users() => guard(() async {
    final u = await api.users();
    await save('users', u.map((e) => e.toJson()).toList());
    return u;
  });
  List<User> cachedUsers() =>
      cached(
        'users',
        (j) => (j as List)
            .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      ) ??
      [];
  Future<Post> create(String title, String body, int userId) => guard(() async {
    title = title.trim();
    body = body.trim();
    if (title.length < 5 ||
        title.length > 100 ||
        body.length < 10 ||
        body.length > 1000 ||
        userId <= 0) {
      throw const AppException(
        ErrorKind.client,
        'Проверьте длину полей и выберите автора.',
      );
    }
    final response = await api.create({
      'title': title,
      'body': body,
      'userId': userId,
    });
    final result = Post(
      id: response.id,
      userId: response.userId,
      title: response.title,
      body: response.body,
      local: true,
    );
    await save(
      'local',
      [...localPosts(), result].map((e) => e.toJson()).toList(),
    );
    return result;
  });
}
