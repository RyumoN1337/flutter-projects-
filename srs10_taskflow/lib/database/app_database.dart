import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
part 'app_database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.production()
    : super(
        LazyDatabase(() async {
          final dir = await getApplicationSupportDirectory();
          await dir.create(recursive: true);
          return NativeDatabase.createInBackground(
            File(p.join(dir.path, 'taskflow.sqlite')),
          );
        }),
      );
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await transaction(() async {
          await customStatement(
            "ALTER TABLE tasks ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low','medium','high','critical'))",
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(deleted_at, priority, deadline)',
          );
        });
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
