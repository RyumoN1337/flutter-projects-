import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:post_explorer/core/error/app_exception.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/models.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';
import 'package:post_explorer/presentation/state/feed_state.dart';

Map<String, dynamic> jsonPost(int id, {int author = 1}) => {
  'id': id,
  'userId': author,
  'title': 'Post title $id',
  'body': 'A sufficiently long post body',
};

class DelayedRepository extends PostRepository {
  DelayedRepository(super.api, super.cache);
  int calls = 0;
  final pending = <Completer<List<Post>>>[];
  @override
  Future<List<Post>> page(int page, int? author, CancelToken token) {
    calls++;
    final c = Completer<List<Post>>();
    pending.add(c);
    return c.future;
  }
}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late PostRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    adapter = DioAdapter(dio: dio);
    repo = PostRepository(
      PostApi(dio),
      PostCache(await SharedPreferences.getInstance()),
    );
  });
  test('JSON -> Post', () {
    final p = Post.fromJson(jsonPost(1));
    expect(p.id, 1);
    expect(p.title, 'Post title 1');
    expect(p.local, false);
  });
  test('Post -> JSON', () {
    expect(Post.fromJson(jsonPost(1)).toJson(), {
      ...jsonPost(1),
      'local': false,
    });
  });
  test('Nested nullable User address', () {
    final u = User.fromJson({
      'id': 1,
      'name': 'Alex',
      'address': {'city': 'Almaty'},
    });
    expect(u.address!.city, 'Almaty');
    expect(u.email, null);
    expect(u.toJson()['address']['city'], 'Almaty');
  });
  test('Repository loads posts through generated Retrofit', () async {
    adapter.onGet(
      '/posts',
      (s) => s.reply(200, [jsonPost(1)]),
      queryParameters: {'_page': 1, '_limit': 10},
    );
    expect((await repo.page(1, null, CancelToken())).single.id, 1);
  });
  test('HTTP 500 becomes server error', () async {
    adapter.onGet(
      '/posts',
      (s) => s.reply(500, {}),
      queryParameters: {'_page': 1, '_limit': 10},
    );
    await expectLater(
      repo.page(1, null, CancelToken()),
      throwsA(
        isA<AppException>().having((e) => e.kind, 'kind', ErrorKind.server),
      ),
    );
  });
  test('Malformed required field becomes JSON error', () async {
    adapter.onGet(
      '/posts',
      (s) => s.reply(200, [
        {'id': 1},
      ]),
      queryParameters: {'_page': 1, '_limit': 10},
    );
    await expectLater(
      repo.page(1, null, CancelToken()),
      throwsA(
        isA<AppException>().having((e) => e.kind, 'kind', ErrorKind.json),
      ),
    );
  });
  test('Title filtering and ID sorting', () {
    final state = FeedState(repo)
      ..posts = [Post.fromJson(jsonPost(1)), Post.fromJson(jsonPost(2))];
    state.search('TITLE 2');
    expect(state.visible.single.id, 2);
    state.search('');
    state.sort();
    expect(state.visible.first.id, 2);
    state.dispose();
  });
  test('Author filter uses userId endpoint', () async {
    adapter.onGet(
      '/posts',
      (s) => s.reply(200, [jsonPost(11, author: 2)]),
      queryParameters: {'userId': 2, '_page': 1, '_limit': 10},
    );
    final state = FeedState(repo);
    await state.filter(2);
    expect(state.visible.single.userId, 2);
    state.dispose();
  });
  test('Concurrent next page requests are deduplicated', () async {
    final delayed = DelayedRepository(repo.api, repo.cache);
    final state = FeedState(delayed);
    final first = state.refresh();
    delayed.pending[0].complete(
      List.generate(10, (i) => Post.fromJson(jsonPost(i + 1))),
    );
    await first;
    final next = state.next();
    final duplicate = state.next();
    expect(delayed.calls, 2);
    delayed.pending[1].complete([
      Post.fromJson(jsonPost(10)),
      Post.fromJson(jsonPost(11)),
    ]);
    await Future.wait([next, duplicate]);
    expect(state.posts.length, 11);
    state.dispose();
  });
  test('Late old filter response cannot overwrite new results', () async {
    final delayed = DelayedRepository(repo.api, repo.cache);
    final state = FeedState(delayed);
    final old = state.filter(1);
    final fresh = state.filter(2);
    delayed.pending[1].complete([Post.fromJson(jsonPost(11, author: 2))]);
    await fresh;
    delayed.pending[0].complete([Post.fromJson(jsonPost(1))]);
    await old;
    expect(state.posts.single.userId, 2);
    state.dispose();
  });
  test('Offline refresh keeps persisted cache', () async {
    await repo.saveFeed(null, [Post.fromJson(jsonPost(1))]);
    adapter.onGet(
      '/posts',
      (s) => s.reply(503, {}),
      queryParameters: {'_page': 1, '_limit': 10},
    );
    final state = FeedState(repo);
    final pending = state.refresh();
    expect(state.posts.single.id, 1);
    expect(state.cached, true);
    await pending;
    expect(state.posts.single.id, 1);
    expect(repo.cachedPosts(null).length, 1);
    expect(state.error, isNotNull);
    state.dispose();
  });
  test('POST response marked local and persisted', () async {
    final data = {
      'title': 'New title',
      'body': 'New post body text',
      'userId': 1,
    };
    adapter.onPost(
      '/posts',
      (s) => s.reply(201, {...data, 'id': 101}),
      data: data,
    );
    final post = await repo.create('New title', 'New post body text', 1);
    expect(post.id, 101);
    expect(post.local, true);
    expect(repo.localPosts().single.title, 'New title');
  });
  test('Invalid form data never reaches POST', () async {
    await expectLater(
      repo.create('a', 'short', 1),
      throwsA(isA<AppException>()),
    );
  });
  test('Timeout and connection errors differ', () {
    expect(
      AppException.from(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ),
      ).kind,
      ErrorKind.timeout,
    );
    expect(
      AppException.from(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      ).kind,
      ErrorKind.connection,
    );
    expect(
      AppException.from(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        ),
      ).kind,
      ErrorKind.client,
    );
  });
}
