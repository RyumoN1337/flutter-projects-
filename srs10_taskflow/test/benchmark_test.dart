import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/repository/task_repository.dart';
import 'package:taskflow/model/models.dart';

void main() {
  test('benchmark 1000 users, 100 projects, 10000 tasks', () async {
    final dir = Directory('reports');
    await dir.create(recursive: true);
    final file = File('reports/benchmark.sqlite');
    // Only the generated benchmark fixture is replaced, never the app database.
    if (await file.exists()) await file.delete();
    final db = AppDatabase(NativeDatabase(file));
    final repo = TaskRepository(db);
    try {
      await repo.query('SELECT 1 FROM users');
      await db.transaction(() async {
        for (var i = 1; i <= 1000; i++) {
          await db.customStatement(
            'INSERT INTO users(id,name,email,registered_at) VALUES(?,?,?,?)',
            [i, 'User $i', 'user$i@example.test', i],
          );
        }
        for (var i = 1; i <= 100; i++) {
          await db.customStatement(
            "INSERT INTO projects(id,name,description,created_at,status) VALUES(?,?,?,?,'active')",
            [i, 'Project $i', 'Benchmark', i],
          );
        }
        for (var i = 1; i <= 1000; i++) {
          await db.customStatement(
            "INSERT INTO project_members VALUES(?,?,'Member')",
            [(i - 1) % 100 + 1, i],
          );
        }
        for (var i = 1; i <= 10000; i++) {
          final user = (i - 1) % 1000 + 1;
          await db.customStatement(
            'INSERT INTO tasks(id,title,description,project_id,assignee_id,priority,status,deadline,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?)',
            [
              i,
              'Task $i',
              'Searchable performance fixture',
              (user - 1) % 100 + 1,
              user,
              ['low', 'medium', 'high', 'critical'][i % 4],
              ['todo', 'inProgress', 'done', 'cancelled'][i % 4],
              day(DateTime(2030, 1, 1 + (i ~/ 1000))),
              i,
              i,
            ],
          );
          await db.customStatement(
            "INSERT INTO task_history(task_id,new_status,actor_id,actor_name,kind,created_at) VALUES(?,?,?,?,'created',?)",
            [
              i,
              ['todo', 'inProgress', 'done', 'cancelled'][i % 4],
              user,
              'User $user',
              i,
            ],
          );
        }
      });
      expect(
        (await repo.query('SELECT COUNT(*) n FROM users')).single['n'],
        1000,
      );
      expect(
        (await repo.query('SELECT COUNT(*) n FROM projects')).single['n'],
        100,
      );
      expect(
        (await repo.query('SELECT COUNT(*) n FROM tasks')).single['n'],
        10000,
      );
      const query =
          "SELECT id,title FROM tasks WHERE project_id=? AND deleted_at IS NULL AND status=? AND (title LIKE ? OR description LIKE ?) ORDER BY deadline,id LIMIT 25 OFFSET 0";
      const args = <Object>[9, 'inProgress', '%Task%', '%Task%'];
      Future<Map<String, Object>> measure() async {
        for (var i = 0; i < 20; i++) {
          await repo.query(query, args);
        }
        final samples = <int>[];
        for (var i = 0; i < 200; i++) {
          final timer = Stopwatch()..start();
          await repo.query(query, args);
          timer.stop();
          samples.add(timer.elapsedMicroseconds);
        }
        samples.sort();
        return {
          'median_us': samples[100],
          'p95_us': samples[190],
          'mean_us': samples.reduce((a, b) => a + b) / samples.length,
          'query_plan': await repo.query('EXPLAIN QUERY PLAN $query', args),
        };
      }

      final indexes = await repo.query(
        "SELECT name,sql FROM sqlite_master WHERE type='index' AND name LIKE 'idx_tasks_%'",
      );
      final withIndexes = await measure();
      final expected = await repo.query(query, args);
      for (final index in indexes) {
        await db.customStatement('DROP INDEX ${index['name']}');
      }
      final withoutIndexes = await measure();
      expect(await repo.query(query, args), expected);
      for (final index in indexes) {
        await db.customStatement(index['sql']);
      }
      final filter = TaskFilter(
        project: 9,
        status: 'inProgress',
        search: 'Task',
        pageSize: 25,
      );
      expect(await repo.tasks(filter).first, hasLength(25));
      expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      final report = {
        'users': 1000,
        'projects': 100,
        'tasks': 10000,
        'warmup': 20,
        'iterations': 200,
        'query': query,
        'parameters': args,
        'with_indexes': withIndexes,
        'without_indexes': withoutIndexes,
        'median_speedup':
            (withoutIndexes['median_us'] as int) /
            (withIndexes['median_us'] as int),
        'note': 'Measured on local machine through Drift. Includes Dart/SQLite call overhead; timings are environment-dependent. Fixture is separate from production database.',
      };
      await File('reports/benchmark.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(report));
    } finally {
      await db.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
