import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lab3/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messages = <String>[];
  setUp(() {
    messages.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('PonnamKarthik/fluttertoast'),
            (call) async {
      if (call.method == 'showToast') {
        messages.add((call.arguments as Map)['msg'] as String);
      }
      return true;
    });
  });

  testWidgets('List selection, greeting, validation and adding an item', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Товар №1'));
    await tester.pump();
    expect(messages.last, 'Вы выбрали: Товар №1');
    await tester.tap(find.text('Показать приветствие'));
    await tester.pump();
    expect(messages.last, 'Hello, Flutter!');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Новый товар');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.scrollUntilVisible(find.text('Новый товар'), 300,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    expect(find.text('Новый товар'), findsOneWidget);
    expect(messages.last, 'Добавлено: Новый товар');
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grid changes color and changes it back', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Сетка'));
    await tester.pumpAndSettle();
    final tile = find.ancestor(of: find.text('1'), matching: find.byType(Material)).first;
    expect(tester.widget<Material>(tile).color, Colors.blue);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(tester.widget<Material>(tile).color, Colors.green);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(tester.widget<Material>(tile).color, Colors.blue);
  });

  testWidgets('All four cards open their own details and return', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Карточки'));
    await tester.pumpAndSettle();
    for (final product in products) {
      final card = find.ancestor(of: find.text(product.name), matching: find.byType(Card));
      await tester.scrollUntilVisible(find.text(product.name), 200);
      final button = find.descendant(of: card, matching: find.text('Подробнее'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(product.details), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Список'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drawer, profile, settings persistence and logout', (tester) async {
    await tester.pumpWidget(const MyApp());
    Future<void> openDrawer() async {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }
    await openDrawer();
    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();
    expect(find.text('Список'), findsOneWidget);
    await openDrawer();
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('student@example.com'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openDrawer();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Выключены'), findsOneWidget);
    expect(messages.last, 'Настройки сохранены');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openDrawer();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openDrawer();
    await tester.tap(find.text('Выход'));
    await tester.pumpAndSettle();
    expect(messages.last, 'Выход из аккаунта');
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}

