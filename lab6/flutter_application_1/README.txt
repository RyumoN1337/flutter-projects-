Запуск:
1. Распакуйте архив, откройте папку flutter_application_1 в VS Code.
2. В терминале (в этой папке) выполните:
     flutter create .
     flutter pub get
     flutter run
(flutter create . добавит папки android/ios/web и не тронет lib/ и pubspec.yaml)
Файл get_posts.g.dart уже сгенерирован. При желании пересоздать:
     dart run build_runner build --delete-conflicting-outputs
Android-эмулятору нужен интернет; на macOS-сборке добавьте network.client в entitlements.
