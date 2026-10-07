import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:registration_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('empty form shows validation errors', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Высокий экран, чтобы вся форма помещалась без прокрутки
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Submit Form'));
    await tester.pump();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm the password'), findsOneWidget);
  });
}
