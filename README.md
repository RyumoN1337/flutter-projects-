# Flutter и Dart — СРС 1 и СРС 2

Учебные работы по предмету «Разработка приложений для мобильных устройств на Flutter/Dart», 2026/2027 учебный год, 7 семестр.

В репозитории два независимых Android-приложения начального уровня. Код каждого экрана находится в одном файле `lib/main.dart`. Используются стандартные виджеты Flutter, без дополнительных библиотек.

| Работа | Папка | Результат |
| --- | --- | --- |
| СРС 1 | [srs1_first_app](srs1_first_app) | Стилизованный текст и синий Container 200 × 100 |
| СРС 2 | [srs2_layout_basics](srs2_layout_basics) | AppBar, Column, два оформленных блока и Row |

## Запуск

Установите Flutter SDK и Android SDK, откройте проект в VS Code или Android Studio и запустите Android-эмулятор либо подключите телефон с USB-отладкой.

Для первой работы:

```sh
cd srs1_first_app
flutter pub get
flutter run
```

Для второй работы, начиная из корня репозитория:

```sh
cd srs2_layout_basics
flutter pub get
flutter run
```

Если подключено несколько устройств, выполните `flutter devices`, затем `flutter run -d <ID устройства>`.
Для Hot Reload сохраните файл и нажмите `r` в терминале с работающим `flutter run`.

## Проверка

В папке каждого проекта:

```sh
flutter analyze
flutter test
```

Среда проверки: Flutter 3.47.4, Dart 3.13.3, Android-эмулятор SRS1_Phone (x86_64).
Подробности и пояснения находятся в README каждой работы.

## Скриншоты Android

### СРС 1

![СРС 1](screenshots/srs1.png)

### СРС 2

![СРС 2](screenshots/srs2.png)
