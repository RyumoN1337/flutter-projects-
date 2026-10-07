# SRSP 5 — Форма регистрации (Flutter)

Приложение из двух экранов: **RegistrationPage** (форма с валидацией) и **UserInfoPage** (данные, прочитанные из SharedPreferences).

## 1. Что должно быть установлено

| Что | Зачем |
|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | сам фреймворк (вместе с ним ставится Dart) |
| [VS Code](https://code.visualstudio.com/) | редактор |
| Расширения **Flutter** и **Dart** (Extensions, `Ctrl+Shift+X`) | запуск и отладка из VS Code |
| Один из вариантов для запуска: **Google Chrome** (проще всего), **Android Studio + эмулятор** или реальный телефон по USB | устройство, на котором запустится приложение |

Проверка установки — в терминале выполните `flutter doctor`. Все пункты для вашей платформы должны быть с зелёной галочкой.

## 2. Запуск проекта в VS Code

1. **Распакуйте** архив, получится папка `registration_app`.
2. В VS Code: **File → Open Folder…** → выберите папку `registration_app`.
3. Откройте терминал: **Terminal → New Terminal** (``Ctrl+` ``).
4. Создайте платформенные папки (android, ios, web и т.д.). Выполняется **один раз**, существующие `lib/` и `pubspec.yaml` команда не перезаписывает:
   ```bash
   flutter create --project-name registration_app .
   ```
5. Скачайте зависимости (shared_preferences):
   ```bash
   flutter pub get
   ```
6. **Выберите устройство** — в правом нижнем углу VS Code (строка состояния) нажмите на название устройства:
   - `Chrome (web)` — самый простой вариант;
   - Android-эмулятор — `Ctrl+Shift+P` → **Flutter: Launch Emulator**;
   - подключённый телефон (включите «Отладку по USB»).
7. Запустите: откройте `lib/main.dart` и нажмите **F5** (или **Run → Start Debugging**).
   То же из терминала: `flutter run` (или `flutter run -d chrome`).

Во время работы горячая перезагрузка — `r` в терминале или значок ⚡ в панели отладки.

## 3. Что проверить после запуска

1. Нажмите **Submit Form** на пустой форме — появятся ошибки, фокус перейдёт на первое неверное поле.
2. **Full Name** — пустое имя не принимается.
3. **Phone Number** — в поле можно вводить только цифры; пустое значение не принимается.
4. **Email Address** — пустое значение и неверный формат (например `abc@` или `abc.com`) не принимаются.
5. **Password** — минимум 6 символов; значок глаза показывает/скрывает пароль.
6. **Confirm Password** — должен совпадать с Password.
7. Кнопка «корзина» очищает поля Full Name и Phone Number.
8. Клавиша «Далее» на клавиатуре переводит фокус на следующее поле (FocusNode).
9. При корректных данных они сохраняются в SharedPreferences и открывается **UserInfoPage**.
10. Кнопка **Delete saved data** на второй странице удаляет данные и возвращает на пустую форму.

Автотест: `flutter test`

## 4. Как выполнены пункты задания

| Пункт задания | Где реализовано |
|---|---|
| Два экрана: RegistrationPage, UserInfoPage | `lib/registration_page.dart`, `lib/user_info_page.dart` |
| Страница, похожая на фото | `RegistrationPage.build()` — AppBar «Register Form», скруглённые поля с иконками, Life Story, счётчик символов, зелёная кнопка |
| Имя не пустое | `_validateName` |
| Email не пустой + формат | `_validateEmail` (RegExp) |
| Пароль не пустой, ≥ 6 символов | `_validatePassword` |
| Подтверждение пароля | `_validateConfirm` — сравнение с `_passController.text` |
| Телефон — только цифры | `_validatePhone` + `FilteringTextInputFormatter.digitsOnly` |
| FocusNode и Controller на каждое поле | поля `_xxxController` и `_xxxFocus` в `_RegistrationPageState`, освобождаются в `dispose()` |
| FormKey | `GlobalKey<FormState> _formKey` |
| obscureText + suffixIcon для пароля | поля Password и Confirm Password, переменные `_hidePass`, `_hideConfirm` |
| Локальное сохранение через SharedPreferences | `lib/user_storage.dart` (save / load / clear) |

> Пароль в SharedPreferences **не сохраняется** намеренно — это хранилище не шифруется. В реальных проектах для паролей и токенов используют `flutter_secure_storage`.

## 5. Структура проекта

```
registration_app/
├── lib/
│   ├── main.dart                 # точка входа, MaterialApp
│   ├── registration_page.dart    # форма регистрации
│   ├── user_info_page.dart       # страница с данными пользователя
│   └── user_storage.dart         # работа с SharedPreferences
├── test/widget_test.dart
├── pubspec.yaml
└── analysis_options.yaml
```

## 6. Частые проблемы

- **`flutter` не найден** — добавьте папку `flutter/bin` в переменную PATH и перезапустите VS Code.
- **Нет устройств в списке** — выполните `flutter devices`; для Chrome должен быть установлен браузер, для эмулятора — Android Studio и созданное виртуальное устройство.
- **`Android license status unknown`** — выполните `flutter doctor --android-licenses` и согласитесь со всеми лицензиями.
- **Windows: «Building with plugins requires symlink support»** — включите режим разработчика: `start ms-settings:developers` → «Режим разработчика».
- **Ошибки после копирования проекта в другое место** — выполните `flutter clean`, затем `flutter pub get`.
- **Красные ошибки импорта в VS Code** — выполните `flutter pub get` и перезапустите Dart-сервер: `Ctrl+Shift+P` → **Dart: Restart Analysis Server**.
