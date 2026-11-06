import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'repository/task_repository.dart';
import 'state/app_state.dart';
import 'presentation/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    TaskFlowApp(state: AppState(TaskRepository(AppDatabase.production()))),
  );
}

class TaskFlowApp extends StatelessWidget {
  final AppState state;
  const TaskFlowApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TaskFlow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5265db)),
      scaffoldBackgroundColor: const Color(0xfff5f6fb),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: HomeScreen(state: state),
  );
}
