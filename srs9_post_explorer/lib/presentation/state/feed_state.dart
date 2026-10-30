import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/models.dart';
import '../../data/repositories/post_repository.dart';

class FeedState extends ChangeNotifier {
  final PostRepository repository;
  FeedState(this.repository);
  List<Post> posts = [], locals = [];
  int? author;
  String query = '';
  bool descending = false,
      refreshing = false,
      loadingMore = false,
      cached = false,
      hasMore = true;
  AppException? error, pageError;
  int _page = 0, _generation = 0;
  bool _disposed = false;
  CancelToken? _token;
  List<Post> get visible {
    final result =
        [...locals.where((p) => author == null || p.userId == author), ...posts]
            .where(
              (p) => p.title.toLowerCase().contains(query.trim().toLowerCase()),
            )
            .toList();
    result.sort(
      (a, b) => descending ? b.id.compareTo(a.id) : a.id.compareTo(b.id),
    );
    return result;
  }

  void emit() {
    if (!_disposed) notifyListeners();
  }

  void search(String value) {
    query = value;
    emit();
  }

  void sort() {
    descending = !descending;
    emit();
  }

  void syncLocals() {
    locals = repository.localPosts();
    emit();
  }

  Future<void> filter(int? value) async {
    author = value;
    await refresh(clear: true);
  }

  Future<void> reset() async {
    query = '';
    descending = false;
    await filter(null);
  }

  Future<void> refresh({bool clear = false}) async {
    final generation = ++_generation;
    _token?.cancel('Filter changed or refresh');
    final token = _token = CancelToken();
    final selected = author;
    if (clear || posts.isEmpty) posts = repository.cachedPosts(selected);
    locals = repository.localPosts();
    cached = posts.isNotEmpty;
    refreshing = true;
    loadingMore = false;
    error = null;
    pageError = null;
    _page = 0;
    hasMore = true;
    emit();
    try {
      final result = await repository.page(1, selected, token);
      if (_disposed || generation != _generation) return;
      posts = result;
      _page = 1;
      hasMore = result.length == 10;
      cached = false;
      await repository.saveFeed(selected, posts);
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = AppException.from(e);
      cached = posts.isNotEmpty;
    } finally {
      if (generation == _generation) {
        refreshing = false;
        emit();
      }
    }
  }

  Future<void> next() async {
    if (_disposed || refreshing || loadingMore || !hasMore || _page == 0) {
      return;
    }
    final generation = _generation;
    final selected = author;
    loadingMore = true;
    pageError = null;
    emit();
    try {
      final result = await repository.page(_page + 1, selected, _token!);
      if (_disposed || generation != _generation) return;
      final ids = posts.map((p) => p.id).toSet();
      posts = [...posts, ...result.where((p) => ids.add(p.id))];
      _page++;
      hasMore = result.length == 10;
      await repository.saveFeed(selected, posts);
    } catch (e) {
      if (generation == _generation) pageError = AppException.from(e);
    } finally {
      if (generation == _generation) {
        loadingMore = false;
        emit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _token?.cancel();
    super.dispose();
  }
}
