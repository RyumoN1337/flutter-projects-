import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/repository/task_repository.dart';
import 'package:taskflow/state/app_state.dart';
import 'package:taskflow/main.dart';

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('all screens fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      final db = AppDatabase(NativeDatabase.memory());
      final repo = TaskRepository(db);
      final state = AppState(repo);
      await tester.runAsync(() async {
        await repo.saveUser('Анна', 'a@example.com');
        await repo.saveProject('Учебный проект', 'Описание', 'active');
      });
      await tester.pumpWidget(TaskFlowApp(state: state));
      for (var i = 0; i < 5; i++) {
        state.update(() => state.section = i);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'section $i');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      state.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
