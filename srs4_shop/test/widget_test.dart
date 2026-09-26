import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srs4_shop/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Favorites, languages and narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('ru'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('ru'),
      saveLocale: false,
      child: const ShopApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Добро пожаловать!'), findsOneWidget);
    await tester.tap(find.text('Каталог').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Избранное').last);
    await tester.pumpAndSettle();
    expect(find.text('Наушники'), findsOneWidget);
    expect(find.text('Рюкзак'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('favorite_1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Пока здесь пусто'), findsOneWidget);
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Английский'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Catalog').last);
    await tester.pumpAndSettle();
    expect(find.text('Headphones'), findsOneWidget);
    expect(find.text('15000 KZT'), findsOneWidget);
    for (final size in [const Size(320, 640), const Size(800, 360)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      for (final tab in ['Home', 'Catalog', 'Favorites', 'Profile']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
