import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:post_explorer/main.dart';
import 'package:post_explorer/data/local/post_cache.dart';
import 'package:post_explorer/data/models/models.dart';
import 'package:post_explorer/data/remote/post_api.dart';
import 'package:post_explorer/data/repositories/post_repository.dart';

// Only the external dependency is replaced. Tests mount the real application,
// screens, Provider state, navigation and form validators.
class ScreenRepository extends PostRepository {
  ScreenRepository(super.api, super.cache);
  int createCalls = 0;
  Completer<Post>? pendingCreate;
  static const examples = [
    Post(
      id: 1,
      userId: 1,
      title: 'Flutter guide',
      body: 'Learn Flutter with real examples.',
    ),
    Post(
      id: 2,
      userId: 2,
      title: 'Dart recipes',
      body: 'Useful Dart patterns for applications.',
    ),
  ];
  @override
  Future<List<Post>> page(int page, int? author, CancelToken token) async =>
      examples.where((p) => author == null || p.userId == author).toList();
  @override
  Future<List<User>> users() async => const [
    User(id: 1, name: 'Alice'),
    User(id: 2, name: 'Bob'),
  ];
  @override
  Future<Post> post(int id) async => examples.singleWhere((p) => p.id == id);
  @override
  Future<List<Comment>> comments(int id) async => [
    Comment(id: 1, postId: id, name: 'Review', body: 'Helpful article'),
  ];
  @override
  Future<Post> create(String title, String body, int userId) async {
    createCalls++;
    return pendingCreate?.future ??
        Future.value(
          Post(id: 101, userId: userId, title: title, body: body, local: true),
        );
  }
}

void main() {
  late ScreenRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = ScreenRepository(
      PostApi(Dio()),
      PostCache(await SharedPreferences.getInstance()),
    );
  });
  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1100, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PostExplorer(repository: repo));
    await tester.pumpAndSettle();
  }

  Future<void> openForm(WidgetTester tester) async {
    await openApp(tester);
    await tester.tap(find.text('Создать пост'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Main screen has title, search, author filter and action buttons',
    (tester) async {
      await openApp(tester);
      expect(find.text('Post Explorer'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.text('Создать пост'), findsOneWidget);
      expect(find.text('По ID'), findsOneWidget);
      expect(find.text('Сбросить'), findsOneWidget);
      expect(find.text('Flutter guide'), findsOneWidget);
      expect(find.text('Dart recipes'), findsOneWidget);
    },
  );
  testWidgets(
    'Search filters posts and Reset clears field and restores results',
    (tester) async {
      await openApp(tester);
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();
      expect(find.text('Flutter guide'), findsOneWidget);
      expect(find.text('Dart recipes'), findsNothing);
      await tester.tap(find.text('Сбросить'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Dart recipes'), findsOneWidget);
    },
  );
  testWidgets('Sort button changes visible order', (tester) async {
    await openApp(tester);
    expect(
      tester.getTopLeft(find.text('Flutter guide')).dy,
      lessThan(tester.getTopLeft(find.text('Dart recipes')).dy),
    );
    await tester.tap(find.text('По ID'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Dart recipes')).dy,
      lessThan(tester.getTopLeft(find.text('Flutter guide')).dy),
    );
  });
  testWidgets('Unknown search shows empty state', (tester) async {
    await openApp(tester);
    await tester.enterText(find.byType(TextField), 'no-match-xyz');
    await tester.pumpAndSettle();
    expect(
      find.text('Посты не найдены. Измените поиск или фильтр.'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets('Post tap opens real detail screen and Back returns to feed', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Flutter guide'));
    await tester.pumpAndSettle();
    expect(find.text('Пост #1'), findsOneWidget);
    expect(find.text('Комментарии · 1'), findsOneWidget);
    expect(find.text('Helpful article'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Post Explorer'), findsOneWidget);
  });
  testWidgets('Create navigation and empty form validation prevent request', (
    tester,
  ) async {
    await openForm(tester);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.tap(find.text('Опубликовать тестовый пост'));
    await tester.pumpAndSettle();
    expect(find.text('Введите от 5 до 100 символов'), findsOneWidget);
    expect(find.text('Введите от 10 до 1000 символов'), findsOneWidget);
    expect(find.text('Выберите автора'), findsOneWidget);
    expect(repo.createCalls, 0);
  });
  testWidgets(
    'Filled form sends once, disables button and displays server response',
    (tester) async {
      repo.pendingCreate = Completer<Post>();
      await openForm(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'New Flutter post',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'A valid body for the new post.',
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опубликовать тестовый пост'));
      await tester.pump();
      expect(repo.createCalls, 1);
      expect(find.text('Отправка…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Отправка…'));
      await tester.pump();
      expect(repo.createCalls, 1);
      repo.pendingCreate!.complete(
        const Post(
          id: 101,
          userId: 1,
          title: 'New Flutter post',
          body: 'A valid body for the new post.',
          local: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Сервер вернул пост #101'), findsOneWidget);
      expect(find.text('Создан локально'), findsOneWidget);
      await tester.tap(find.text('К списку постов'));
      await tester.pumpAndSettle();
      expect(find.text('Post Explorer'), findsOneWidget);
    },
  );
}
