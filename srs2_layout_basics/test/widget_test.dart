import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_basics/main.dart';

void main() {
  testWidgets('Макет отображается на экране телефона', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('Lab 3: Layout Basics'), findsOneWidget);
    expect(find.text('Welcome to Flutter!'), findsOneWidget);
    expect(find.text('Left Text'), findsOneWidget);
    expect(find.text('Right Text'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Left Text')).dx,
      lessThan(tester.getTopLeft(find.text('Right Text')).dx),
    );
    expect(tester.takeException(), isNull);
  });
}

