import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/main.dart';

void main() {
  testWidgets('Первый экран отображается без ошибок', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Моё первое приложение!'), findsOneWidget);
    final rectangle = find.byWidgetPredicate(
      (widget) => widget is Container && widget.color == Colors.blue,
    );
    expect(tester.getSize(rectangle), const Size(200, 100));
    expect(tester.takeException(), isNull);
  });
}
