import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:taskflow/database/app_database.dart';
import 'package:taskflow/model/models.dart';
import 'package:taskflow/repository/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late int user, project;
  final deadline = DateTime(2030, 5, 20);
  Future<int> create({
    String title = 'Task',
    String description = 'Description',
    String status = 'todo',
    String priority = 'medium',
    int? assignee,
    int? projectId,
    DateTime? date,
  }) => repo.saveTask(
    title: title,
    description: description,
    project: projectId ?? project,
    assignee: assignee ?? user,
    priority: priority,
    status: status,
    deadline: date ?? deadline,
    actor: user,
  );
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TaskRepository(db);
    user = await repo.saveUser('Анна', 'anna@example.com');
    project = await repo.saveProject('Проект', 'Описание', 'active');
    await repo.addMember(project, user, 'Owner');
  });
  tearDown(() async {
    await db.close();
  });
  test('create and update user, registration retained', () async {
    final before = (await repo.users().first).first;
    await repo.saveUser('Анна 2', 'new@example.com', id: user);
    final after = (await repo.users().first).first;
    expect(after['name'], 'Анна 2');
    expect(after['registered_at'], before['registered_at']);
  });
  test('email unique ignoring case and whitespace', () async {
    await expectLater(
      repo.saveUser('Other', ' ANNA@example.com '),
      throwsA(isA<RuleException>()),
    );
  });
  test('invalid user rejected', () async {
    await expectLater(
      repo.saveUser('', 'broken'),
      throwsA(isA<RuleException>()),
    );
  });
  test('delete unassigned user and memberships', () async {
    await repo.deleteUser(user);
    expect(await repo.users().first, isEmpty);
    expect(await repo.members(project).first, isEmpty);
  });
  test('cannot delete user with unfinished task even in trash', () async {
    final id = await create();
    await repo.trashTask(id);
    await expectLater(repo.deleteUser(user), throwsA(isA<RuleException>()));
  });
  test('delete user with done tasks preserves actor snapshot', () async {
    final id = await create(status: 'done');
    await repo.deleteUser(user);
    expect((await repo.task(id))['assignee_id'], isNull);
    expect((await repo.history(id).first).first['actor_name'], 'Анна');
  });
  test('project create and edit', () async {
    await repo.saveProject(
      'Новый',
      'Текст',
      'archived',
      id: project,
      completedAt: day(deadline),
    );
    expect((await repo.projects().first).first['status'], 'archived');
  });
  test('many to many membership and role update', () async {
    final second = await repo.saveProject('2', '', 'active');
    await repo.addMember(second, user, 'Member');
    await repo.changeRole(project, user, 'Admin');
    expect((await repo.members(project).first).first['role'], 'Admin');
    expect(await repo.members(second).first, hasLength(1));
  });
  test('duplicate membership rejected', () async {
    await expectLater(
      repo.addMember(project, user, 'Member'),
      throwsA(isA<RuleException>()),
    );
  });
  test('cannot remove member with pending tasks', () async {
    await create();
    await expectLater(
      repo.removeMember(project, user),
      throwsA(isA<RuleException>()),
    );
  });
  test('task creation includes initial history', () async {
    final id = await create();
    final h = await repo.history(id).first;
    expect(h, hasLength(1));
    expect(h.first['kind'], 'created');
    expect(h.first['old_status'], isNull);
    expect(h.first['actor_id'], user);
  });
  test('nonmember assignee rejected', () async {
    final outsider = await repo.saveUser('Другой', 'other@example.com');
    await expectLater(
      create(assignee: outsider),
      throwsA(isA<RuleException>()),
    );
    expect(await repo.tasks(const TaskFilter()).first, isEmpty);
  });
  test('missing project rejected', () async {
    await expectLater(create(projectId: 99999), throwsA(isA<RuleException>()));
  });
  test('fourth unfinished task on same calendar day rejected', () async {
    for (var i = 0; i < 3; i++) {
      await create(date: DateTime(2030, 5, 20, i));
    }
    await expectLater(
      create(date: DateTime(2030, 5, 20, 23, 59)),
      throwsA(isA<RuleException>()),
    );
    expect(await create(date: DateTime(2030, 5, 21)), isPositive);
  });
  test('done and cancelled tasks do not consume capacity', () async {
    for (var i = 0; i < 5; i++) {
      await create(status: i.isEven ? 'done' : 'cancelled');
    }
    expect(await create(), isPositive);
  });
  test('status update and persistent history', () async {
    final id = await create();
    await repo.setStatus(id, 'inProgress', user);
    expect((await repo.task(id))['status'], 'inProgress');
    final h = (await repo.history(id).first).first;
    expect(h['old_status'], 'todo');
    expect(h['new_status'], 'inProgress');
  });
  test('same status does not add history', () async {
    final id = await create();
    await repo.setStatus(id, 'todo', user);
    expect(await repo.history(id).first, hasLength(1));
  });
  test('undo latest status once and records event', () async {
    final id = await create();
    await repo.setStatus(id, 'inProgress', user);
    await repo.undoStatus(id, user);
    expect((await repo.task(id))['status'], 'todo');
    expect((await repo.history(id).first).first['kind'], 'undo');
    await expectLater(repo.undoStatus(id, user), throwsA(isA<RuleException>()));
  });
  test('creation rolls back when history insert fails', () async {
    await db.customStatement(
      "CREATE TRIGGER reject_history BEFORE INSERT ON task_history BEGIN SELECT RAISE(ABORT,'history failure'); END",
    );
    await expectLater(create(), throwsA(anything));
    expect(await repo.query('SELECT * FROM tasks'), isEmpty);
  });
  test('reassignment and event roll back together', () async {
    final id = await create();
    final other = await repo.saveUser('Борис', 'boris@example.com');
    await repo.addMember(project, other, 'Member');
    await db.customStatement(
      "CREATE TRIGGER reject_history BEFORE INSERT ON task_history BEGIN SELECT RAISE(ABORT,'history failure'); END",
    );
    await expectLater(
      repo.saveTask(
        id: id,
        title: 'Task',
        description: '',
        project: project,
        assignee: other,
        priority: 'high',
        status: 'todo',
        deadline: deadline,
        actor: user,
      ),
      throwsA(anything),
    );
    expect((await repo.task(id))['assignee_id'], user);
    expect((await repo.task(id))['priority'], 'medium');
  });
  test('successful reassignment records both ids', () async {
    final id = await create();
    final other = await repo.saveUser('Борис', 'boris@example.com');
    await repo.addMember(project, other, 'Member');
    await repo.saveTask(
      id: id,
      title: 'Task',
      description: '',
      project: project,
      assignee: other,
      priority: 'high',
      status: 'todo',
      deadline: deadline,
      actor: user,
    );
    final h = (await repo.history(id).first).first;
    expect(h['kind'], 'assignment');
    expect(h['old_assignee_id'], user);
    expect(h['new_assignee_id'], other);
  });
  test('comment added and only author can delete', () async {
    final id = await create();
    await repo.addComment(id, user, 'Привет');
    final c = (await repo.comments(id).first).single;
    final other = await repo.saveUser('Борис', 'b@example.com');
    await expectLater(
      repo.deleteComment(c['id'], other),
      throwsA(isA<RuleException>()),
    );
    await repo.deleteComment(c['id'], user);
    expect(await repo.comments(id).first, isEmpty);
  });
  test('comment for nonexistent task rejected', () async {
    await expectLater(repo.addComment(999, user, 'text'), throwsA(anything));
  });
  test('soft delete keeps task and history but hides main list', () async {
    final id = await create();
    await repo.trashTask(id);
    expect(await repo.tasks(const TaskFilter()).first, isEmpty);
    expect(await repo.tasks(const TaskFilter(trash: true)).first, hasLength(1));
    expect(await repo.history(id).first, hasLength(1));
  });
  test('restore task', () async {
    final id = await create();
    await repo.trashTask(id);
    await repo.restoreTask(id);
    expect(await repo.tasks(const TaskFilter()).first, hasLength(1));
  });
  test('restore enforces capacity limit', () async {
    final id = await create();
    await repo.trashTask(id);
    for (var i = 0; i < 3; i++) {
      await create();
    }
    await expectLater(repo.restoreTask(id), throwsA(isA<RuleException>()));
    expect((await repo.task(id))['deleted_at'], isNotNull);
  });
  test('purge cascades comments history and attachment metadata', () async {
    final id = await create();
    await repo.addComment(id, user, 'text');
    await repo.trashTask(id);
    await repo.purgeTask(id);
    expect(await repo.query('SELECT * FROM tasks'), isEmpty);
    expect(await repo.history(id).first, isEmpty);
    expect(await repo.comments(id).first, isEmpty);
  });
  test('project deletion cascades', () async {
    await create();
    await repo.deleteProject(project);
    expect(await repo.query('SELECT * FROM tasks'), isEmpty);
    expect(await repo.query('SELECT * FROM task_history'), isEmpty);
    expect(await repo.members(project).first, isEmpty);
  });
  test('SQL statistics exclude trash and cancelled from unfinished', () async {
    await create(status: 'done');
    await create(status: 'cancelled');
    await create(date: DateTime(2020), priority: 'critical');
    final deleted = await create();
    await repo.trashTask(deleted);
    final totals = (await repo.totals().first).single;
    expect(totals['total'], 3);
    expect(totals['done'], 1);
    expect(totals['pending'], 1);
    expect(totals['overdue'], 1);
    expect(
      (await repo.projectStats().first).single['percent'],
      closeTo(100 / 3, 0.001),
    );
  });
  test('combined filters and title/description search', () async {
    await create(title: 'Alpha', description: 'needle', priority: 'high');
    await create(title: 'Beta', status: 'done');
    expect(
      await repo
          .tasks(
            TaskFilter(
              search: 'needle',
              priority: 'high',
              status: 'todo',
              assignee: user,
              project: project,
            ),
          )
          .first,
      hasLength(1),
    );
    expect(
      await repo.tasks(const TaskFilter(search: 'Beta')).first,
      hasLength(1),
    );
    expect(
      await repo.tasks(const TaskFilter(search: "' OR 1=1 --")).first,
      isEmpty,
    );
  });
  test('pagination with deterministic sorting', () async {
    for (var i = 0; i < 7; i++) {
      await create(title: 'Task $i', date: DateTime(2030, 5, 20 + i));
    }
    final a = await repo.tasks(const TaskFilter(pageSize: 3)).first;
    final b = await repo.tasks(const TaskFilter(pageSize: 3, page: 1)).first;
    expect(a, hasLength(3));
    expect(b, hasLength(3));
    expect(
      a.map((r) => r['id']).toSet().intersection(b.map((r) => r['id']).toSet()),
      isEmpty,
    );
    expect(a.first['deadline'], lessThan(b.first['deadline']));
  });
  test('watch emits after repository mutation', () async {
    final stream = repo.users();
    final future = expectLater(
      stream.map((r) => r.length),
      emitsInOrder([1, 2]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await repo.saveUser('Борис', 'b@example.com');
    await future;
  });
  test('attachment is copied and DB stores path only', () async {
    final dir = await Directory.systemTemp.createTemp('taskflow_files');
    try {
      final source = File('${dir.path}/source.txt');
      await source.writeAsString('offline');
      final id = await create();
      await repo.attachFile(id, source.path, storage: dir);
      await source.delete();
      final a = (await repo.attachments(id).first).single;
      expect(await File(a['local_path']).readAsString(), 'offline');
      expect(
        a.keys,
        containsAll(['name', 'local_path', 'task_id', 'created_at']),
      );
      await repo.deleteAttachment(a['id']);
      expect(await File(a['local_path']).exists(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('file database survives reopen including history', () async {
    final dir = await Directory.systemTemp.createTemp('taskflow_persist');
    final file = File('${dir.path}/db.sqlite');
    var disk = AppDatabase(NativeDatabase(file));
    try {
      var r = TaskRepository(disk);
      final u = await r.saveUser('User', 'user@example.com');
      final p = await r.saveProject('Project', '', 'active');
      await r.addMember(p, u, 'Owner');
      final id = await r.saveTask(
        title: 'Persistent',
        description: '',
        project: p,
        assignee: u,
        priority: 'high',
        status: 'todo',
        deadline: deadline,
        actor: u,
      );
      await disk.close();
      disk = AppDatabase(NativeDatabase(file));
      r = TaskRepository(disk);
      expect((await r.task(id))['title'], 'Persistent');
      expect(await r.history(id).first, hasLength(1));
    } finally {
      await disk.close();
      await dir.delete(recursive: true);
    }
  });
  test('v1 to v2 migration preserves records and sets medium', () async {
    final dir = await Directory.systemTemp.createTemp('taskflow_migration');
    final file = File('${dir.path}/v1.sqlite');
    final raw = sql.sqlite3.open(file.path);
    final schema = await File('lib/database/schema.drift').readAsString();
    final v1 = schema
        .split('\n')
        .where(
          (line) =>
              !line.trimLeft().startsWith('priority TEXT') &&
              !line.startsWith('CREATE INDEX idx_tasks_priority'),
        )
        .join('\n');
    raw.execute(v1);
    raw.execute(
      "INSERT INTO users VALUES(1,'Legacy','legacy@example.com',1000); INSERT INTO projects VALUES(1,'Legacy project','keep',1000,NULL,'active'); INSERT INTO project_members VALUES(1,1,'Owner'); INSERT INTO tasks(id,title,description,project_id,assignee_id,status,deadline,created_at,updated_at) VALUES(1,'Legacy task','preserved',1,1,'todo',1000,1000,1000); PRAGMA user_version=1;",
    );
    raw.close();
    final migrated = AppDatabase(NativeDatabase(file));
    try {
      final r = TaskRepository(migrated);
      final t = await r.task(1);
      expect(t['priority'], 'medium');
      expect(t['description'], 'preserved');
      expect((await r.users().first).single['email'], 'legacy@example.com');
      expect(await r.query('PRAGMA foreign_key_check'), isEmpty);
      expect((await r.query('PRAGMA user_version')).single['user_version'], 2);
    } finally {
      await migrated.close();
      await dir.delete(recursive: true);
    }
  });
}
