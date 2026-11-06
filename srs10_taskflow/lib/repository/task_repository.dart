import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../model/models.dart';

class TaskRepository {
  final AppDatabase db;
  TaskRepository(this.db);
  List<Variable> _vars(List<Object> args) => args
      .map((a) => a is int ? Variable<int>(a) : Variable<String>(a as String))
      .toList();
  Future<List<DbRow>> query(String sql, [List<Object> args = const []]) async =>
      (await db.customSelect(sql, variables: _vars(args)).get())
          .map((r) => r.data)
          .toList();
  Stream<List<DbRow>> watch(String sql, [List<Object> args = const []]) => db
      .customSelect(
        sql,
        variables: _vars(args),
        readsFrom: db.allTables.toSet(),
      )
      .watch()
      .map((rows) => rows.map((r) => r.data).toList());
  Future<int> _write(String sql, [List<Object> args = const []]) => db
      .customInsert(sql, variables: _vars(args), updates: db.allTables.toSet());
  int get now => DateTime.now().millisecondsSinceEpoch;
  void _required(String value, String label) {
    if (value.trim().isEmpty) throw RuleException('Заполните поле «$label».');
  }

  Future<DbRow> _one(String table, int id) async {
    final rows = await query('SELECT * FROM $table WHERE id = ?', [id]);
    if (rows.isEmpty) throw RuleException('Запись больше не существует.');
    return rows.first;
  }

  Future<DbRow> task(int id) => _one('tasks', id);
  Future<DbRow> _actor(int id) => _one('users', id);
  Stream<List<DbRow>> users() =>
      watch('SELECT * FROM users ORDER BY name COLLATE NOCASE');
  Stream<List<DbRow>> projects() =>
      watch('SELECT * FROM projects ORDER BY created_at DESC');
  Stream<List<DbRow>> members(int project) => watch(
    'SELECT m.*, u.name, u.email FROM project_members m JOIN users u ON u.id=m.user_id WHERE project_id=? ORDER BY u.name',
    [project],
  );
  Future<List<DbRow>> memberChoices(int project) => query(
    'SELECT u.* FROM users u JOIN project_members m ON m.user_id=u.id WHERE m.project_id=? ORDER BY name',
    [project],
  );
  Future<int> saveUser(String name, String email, {int? id}) async {
    _required(name, 'Имя');
    email = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw RuleException('Введите корректный email.');
    }
    return db.transaction(() async {
      if ((await query(
        'SELECT id FROM users WHERE email=? COLLATE NOCASE AND id<>?',
        [email, id ?? -1],
      )).isNotEmpty) {
        throw RuleException('Этот email уже зарегистрирован.');
      }
      if (id != null) {
        await _one('users', id);
        await _write('UPDATE users SET name=?,email=? WHERE id=?', [
          name.trim(),
          email,
          id,
        ]);
        return id;
      }
      return _write(
        'INSERT INTO users(name,email,registered_at) VALUES(?,?,?)',
        [name.trim(), email, now],
      );
    });
  }

  Future<void> deleteUser(int id) => db.transaction(() async {
    if ((await query(
      "SELECT id FROM tasks WHERE assignee_id=? AND status IN ('todo','inProgress') LIMIT 1",
      [id],
    )).isNotEmpty) {
      throw RuleException(
        'У пользователя есть незавершённые задачи, в том числе возможные задачи в корзине.',
      );
    }
    await _write('DELETE FROM users WHERE id=?', [id]);
  });
  Future<int> saveProject(
    String name,
    String description,
    String status, {
    int? id,
    int? completedAt,
  }) async {
    _required(name, 'Название');
    if (!projectStatuses.containsKey(status)) {
      throw RuleException('Некорректный статус проекта.');
    }
    if (id == null) {
      return _write(
        'INSERT INTO projects(name,description,status,created_at,completed_at) VALUES(?,?,?,?,${completedAt == null ? 'NULL' : '?'})',
        [name.trim(), description.trim(), status, now, ?completedAt],
      );
    }
    await _one('projects', id);
    await _write(
      'UPDATE projects SET name=?,description=?,status=?,completed_at=${completedAt == null ? 'NULL' : '?'} WHERE id=?',
      [name.trim(), description.trim(), status, ?completedAt, id],
    );
    return id;
  }

  Future<void> deleteProject(int id) async {
    await _write('DELETE FROM projects WHERE id=?', [id]);
  }

  Future<void> addMember(int project, int user, String role) async {
    if (!roles.containsKey(role)) throw RuleException('Некорректная роль.');
    if ((await query(
      'SELECT 1 FROM project_members WHERE project_id=? AND user_id=?',
      [project, user],
    )).isNotEmpty) {
      throw RuleException('Пользователь уже состоит в проекте.');
    }
    await _write(
      'INSERT INTO project_members(project_id,user_id,role) VALUES(?,?,?)',
      [project, user, role],
    );
  }

  Future<void> changeRole(int project, int user, String role) async {
    if (!roles.containsKey(role)) throw RuleException('Некорректная роль.');
    await _write(
      'UPDATE project_members SET role=? WHERE project_id=? AND user_id=?',
      [role, project, user],
    );
  }

  Future<void> removeMember(int project, int user) => db.transaction(() async {
    if ((await query(
      "SELECT id FROM tasks WHERE project_id=? AND assignee_id=? AND status IN ('todo','inProgress') LIMIT 1",
      [project, user],
    )).isNotEmpty) {
      throw RuleException(
        'Сначала переназначьте незавершённые задачи участника.',
      );
    }
    await _write(
      'UPDATE tasks SET assignee_id=NULL,updated_at=? WHERE project_id=? AND assignee_id=?',
      [now, project, user],
    );
    await _write(
      'DELETE FROM project_members WHERE project_id=? AND user_id=?',
      [project, user],
    );
  });
  Future<void> _validateAssignment(
    int project,
    int? assignee,
    int deadline,
    String status,
    int? exclude,
  ) async {
    if (assignee == null ||
        (await query(
          'SELECT 1 FROM project_members WHERE project_id=? AND user_id=?',
          [project, assignee],
        )).isEmpty) {
      throw RuleException(
        'Исполнитель должен быть участником выбранного проекта.',
      );
    }
    if (status == 'done' || status == 'cancelled') return;
    final count =
        (await query(
              "SELECT COUNT(*) AS n FROM tasks WHERE assignee_id=? AND deadline=? AND status IN ('todo','inProgress') AND deleted_at IS NULL AND id<>?",
              [assignee, deadline, exclude ?? -1],
            )).first['n']
            as int;
    if (count >= 3) {
      throw RuleException(
        'На эту дату у исполнителя уже есть три незавершённые задачи.',
      );
    }
  }

  Future<void> _history(
    int task,
    int actor,
    String kind,
    String? oldStatus,
    String newStatus, {
    int? oldAssignee,
    int? newAssignee,
  }) async {
    final user = await _actor(actor);
    await _write(
      'INSERT INTO task_history(task_id,actor_id,actor_name,kind,old_status,new_status,old_assignee_id,new_assignee_id,created_at) VALUES(?,?,?,?,${oldStatus == null ? 'NULL' : '?'},?,${oldAssignee == null ? 'NULL' : '?'},${newAssignee == null ? 'NULL' : '?'},?)',
      [
        task,
        actor,
        user['name'] as String,
        kind,
        ?oldStatus,
        newStatus,
        ?oldAssignee,
        ?newAssignee,
        now,
      ],
    );
  }

  Future<int> saveTask({
    int? id,
    required String title,
    required String description,
    required int project,
    required int assignee,
    required String priority,
    required String status,
    required DateTime deadline,
    required int actor,
  }) => db.transaction(() async {
    _required(title, 'Название');
    if (!statuses.containsKey(status) || !priorities.containsKey(priority)) {
      throw RuleException('Некорректный статус или приоритет.');
    }
    await _one('projects', project);
    await _actor(actor);
    final date = day(deadline);
    await _validateAssignment(project, assignee, date, status, id);
    if (id == null) {
      final newId = await _write(
        'INSERT INTO tasks(title,description,project_id,assignee_id,priority,status,deadline,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?)',
        [
          title.trim(),
          description.trim(),
          project,
          assignee,
          priority,
          status,
          date,
          now,
          now,
        ],
      );
      await _history(
        newId,
        actor,
        'created',
        null,
        status,
        newAssignee: assignee,
      );
      return newId;
    }
    final old = await task(id);
    await _write(
      'UPDATE tasks SET title=?,description=?,project_id=?,assignee_id=?,priority=?,status=?,deadline=?,updated_at=? WHERE id=?',
      [
        title.trim(),
        description.trim(),
        project,
        assignee,
        priority,
        status,
        date,
        now,
        id,
      ],
    );
    if (old['status'] != status) {
      await _history(id, actor, 'status', old['status'], status);
    }
    if (old['assignee_id'] != assignee || old['project_id'] != project) {
      await _history(
        id,
        actor,
        'assignment',
        old['status'],
        status,
        oldAssignee: old['assignee_id'],
        newAssignee: assignee,
      );
    }
    return id;
  });
  Future<void> setStatus(int id, String status, int actor) =>
      db.transaction(() async {
        if (!statuses.containsKey(status)) {
          throw RuleException('Неизвестный статус.');
        }
        final old = await task(id);
        if (old['deleted_at'] != null) {
          throw RuleException('Сначала восстановите задачу.');
        }
        if (old['status'] == status) return;
        await _validateAssignment(
          old['project_id'],
          old['assignee_id'],
          old['deadline'],
          status,
          id,
        );
        await _write('UPDATE tasks SET status=?,updated_at=? WHERE id=?', [
          status,
          now,
          id,
        ]);
        await _history(id, actor, 'status', old['status'], status);
      });
  Future<void> undoStatus(int id, int actor) => db.transaction(() async {
    final rows = await query(
      "SELECT * FROM task_history WHERE task_id=? AND kind='status' ORDER BY id DESC LIMIT 1",
      [id],
    );
    if (rows.isEmpty || rows.first['undone'] == 1) {
      throw RuleException('Нет изменения статуса для отмены.');
    }
    final event = rows.first;
    final current = await task(id);
    if (current['deleted_at'] != null) {
      throw RuleException('Сначала восстановите задачу.');
    }
    await _validateAssignment(
      current['project_id'],
      current['assignee_id'],
      current['deadline'],
      event['old_status'],
      id,
    );
    await _write('UPDATE tasks SET status=?,updated_at=? WHERE id=?', [
      event['old_status'],
      now,
      id,
    ]);
    await _write('UPDATE task_history SET undone=1 WHERE id=?', [event['id']]);
    await _history(id, actor, 'undo', current['status'], event['old_status']);
  });
  Future<void> trashTask(int id) async {
    await _write('UPDATE tasks SET deleted_at=?,updated_at=? WHERE id=?', [
      now,
      now,
      id,
    ]);
  }

  Future<void> restoreTask(int id) => db.transaction(() async {
    final old = await task(id);
    await _validateAssignment(
      old['project_id'],
      old['assignee_id'],
      old['deadline'],
      old['status'],
      id,
    );
    await _write('UPDATE tasks SET deleted_at=NULL,updated_at=? WHERE id=?', [
      now,
      id,
    ]);
  });
  Future<void> purgeTask(int id) async {
    await _write('DELETE FROM tasks WHERE id=? AND deleted_at IS NOT NULL', [
      id,
    ]);
  }

  (String, List<Object>) _filter(TaskFilter f) {
    final clauses = <String>['t.deleted_at IS ${f.trash ? 'NOT ' : ''}NULL'];
    final args = <Object>[];
    for (final entry in {
      'status': f.status,
      'priority': f.priority,
      'assignee_id': f.assignee,
      'project_id': f.project,
    }.entries) {
      if (entry.value != null) {
        clauses.add('t.${entry.key}=?');
        args.add(entry.value!);
      }
    }
    if (f.search.trim().isNotEmpty) {
      // instr treats %, _ and quotes literally. SQLite lower() folds ASCII only.
      clauses.add(
        '(instr(lower(t.title),lower(?))>0 OR instr(lower(t.description),lower(?))>0)',
      );
      args.addAll([f.search.trim(), f.search.trim()]);
    }
    return (clauses.join(' AND '), args);
  }

  Stream<List<DbRow>> tasks(TaskFilter f) {
    final (where, args) = _filter(f);
    final sort = f.sort == 'created_at' ? 'created_at' : 'deadline';
    return watch(
      'SELECT t.*, p.name AS project_name,u.name AS assignee_name FROM tasks t JOIN projects p ON p.id=t.project_id LEFT JOIN users u ON u.id=t.assignee_id WHERE $where ORDER BY t.$sort ${f.ascending ? 'ASC' : 'DESC'},t.id LIMIT ? OFFSET ?',
      [...args, f.pageSize, f.page * f.pageSize],
    );
  }

  Stream<List<DbRow>> taskCount(TaskFilter f) {
    final (where, args) = _filter(f);
    return watch('SELECT COUNT(*) AS n FROM tasks t WHERE $where', args);
  }

  Stream<List<DbRow>> taskDetails(int id) => watch(
    'SELECT t.*,p.name AS project_name,u.name AS assignee_name FROM tasks t JOIN projects p ON p.id=t.project_id LEFT JOIN users u ON u.id=t.assignee_id WHERE t.id=?',
    [id],
  );
  Stream<List<DbRow>> history(int id) => watch(
    'SELECT * FROM task_history WHERE task_id=? ORDER BY id DESC',
    [id],
  );
  Stream<List<DbRow>> comments(int id) =>
      watch('SELECT * FROM comments WHERE task_id=? ORDER BY id DESC', [id]);
  Stream<List<DbRow>> attachments(int id) =>
      watch('SELECT * FROM attachments WHERE task_id=? ORDER BY id DESC', [id]);
  Future<void> addComment(int task, int author, String body) =>
      db.transaction(() async {
        _required(body, 'Комментарий');
        final user = await _actor(author);
        await _one('tasks', task);
        await _write(
          'INSERT INTO comments(task_id,author_id,author_name,body,created_at) VALUES(?,?,?,?,?)',
          [task, author, user['name'], body.trim(), now],
        );
      });
  Future<void> deleteComment(int id, int actor) => db.transaction(() async {
    final row = await _one('comments', id);
    if (row['author_id'] != actor) {
      throw RuleException('Удалить комментарий может только его автор.');
    }
    await _write('DELETE FROM comments WHERE id=?', [id]);
  });
  Future<void> attachFile(int task, String source, {Directory? storage}) async {
    await _one('tasks', task);
    final root = storage ?? await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'attachments', task.toString()));
    await dir.create(recursive: true);
    final name = p.basename(source);
    final dest = File(
      p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}_$name'),
    );
    await File(source).copy(dest.path);
    try {
      await _write(
        'INSERT INTO attachments(task_id,name,local_path,created_at) VALUES(?,?,?,?)',
        [task, name, dest.path, now],
      );
    } catch (_) {
      await dest.delete();
      rethrow;
    }
  }

  Future<void> deleteAttachment(int id) async {
    final row = await _one('attachments', id);
    await _write('DELETE FROM attachments WHERE id=?', [id]);
    final file = File(row['local_path']);
    if (await file.exists()) await file.delete();
  }

  Stream<List<DbRow>> totals() => watch(
    "SELECT (SELECT COUNT(*) FROM projects) AS projects, COUNT(*) AS total, COALESCE(SUM(status='done'),0) AS done, COALESCE(SUM(status IN ('todo','inProgress')),0) AS pending, COALESCE(SUM(status IN ('todo','inProgress') AND deadline < ?),0) AS overdue FROM tasks WHERE deleted_at IS NULL",
    [day(DateTime.now())],
  );
  Stream<List<DbRow>> priorityStats() => watch(
    "SELECT priority,COUNT(*) AS n FROM tasks WHERE deleted_at IS NULL GROUP BY priority",
  );
  Stream<List<DbRow>> assigneeStats() => watch(
    'SELECT u.id,u.name,COUNT(t.id) AS n FROM users u LEFT JOIN tasks t ON t.assignee_id=u.id AND t.deleted_at IS NULL GROUP BY u.id ORDER BY n DESC,u.name',
  );
  Stream<List<DbRow>> projectStats() => watch(
    "SELECT p.id,p.name,COUNT(t.id) AS total,COALESCE(SUM(t.status='done'),0) AS done,CASE WHEN COUNT(t.id)=0 THEN 0.0 ELSE 100.0*SUM(t.status='done')/COUNT(t.id) END AS percent FROM projects p LEFT JOIN tasks t ON t.project_id=p.id AND t.deleted_at IS NULL GROUP BY p.id ORDER BY p.name",
  );
}
