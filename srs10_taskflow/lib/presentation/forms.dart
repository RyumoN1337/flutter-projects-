import 'package:flutter/material.dart';

import '../model/models.dart';
import '../repository/task_repository.dart';

Future<void> runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is RuleException ? e.message : 'Ошибка: $e')),
      );
    }
  }
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    ) ??
    false;
Widget choice(
  String label,
  dynamic value,
  Map<dynamic, String> options,
  ValueChanged<dynamic> changed, {
  bool nullable = false,
}) => DropdownButtonFormField<dynamic>(
  initialValue: options.containsKey(value) ? value : null,
  isExpanded: true,
  decoration: InputDecoration(labelText: label),
  items: [
    if (nullable) const DropdownMenuItem(value: null, child: Text('Все')),
    ...options.entries.map(
      (e) => DropdownMenuItem(
        value: e.key,
        child: Text(e.value, overflow: TextOverflow.ellipsis),
      ),
    ),
  ],
  onChanged: changed,
);
Future<void> editRecord(
  BuildContext context,
  TaskRepository repo,
  String kind, {
  DbRow? row,
  int? actor,
  int? project,
}) async {
  final projects = await repo.projects().first;
  if (!context.mounted) return;
  final name = TextEditingController(
    text: row?[kind == 'task' ? 'title' : 'name'] ?? '',
  );
  final description = TextEditingController(text: row?['description'] ?? '');
  final email = TextEditingController(text: row?['email'] ?? '');
  int? selectedProject =
      row?['project_id'] ??
      project ??
      (projects.isEmpty ? null : projects.first['id']);
  var members = selectedProject == null
      ? <DbRow>[]
      : await repo.memberChoices(selectedProject);
  int? assignee =
      row?['assignee_id'] ?? (members.isEmpty ? null : members.first['id']);
  String status = row?['status'] ?? (kind == 'project' ? 'active' : 'todo');
  String priority = row?['priority'] ?? 'medium';
  DateTime deadline = row?['deadline'] == null
      ? DateTime.now()
      : DateTime.fromMillisecondsSinceEpoch(row!['deadline']);
  DateTime? completed = row?['completed_at'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(row!['completed_at']);
  String? error;
  bool busy = false;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        title: Text(
          '${row == null ? 'Создать' : 'Изменить'} ${kind == 'user'
              ? 'пользователя'
              : kind == 'project'
              ? 'проект'
              : 'задачу'}',
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: kind == 'user' ? 'Имя' : 'Название',
                  ),
                ),
                const SizedBox(height: 16),
                if (kind == 'user')
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                if (kind != 'user') ...[
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Описание'),
                  ),
                  const SizedBox(height: 16),
                  choice(
                    'Статус',
                    status,
                    kind == 'project' ? projectStatuses : statuses,
                    (v) => set(() => status = v),
                  ),
                  const SizedBox(height: 16),
                ],
                if (kind == 'project')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Дата завершения'),
                    subtitle: Text(
                      completed == null
                          ? 'Не указана'
                          : dateText(completed!.millisecondsSinceEpoch),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => set(() => completed = null),
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: c,
                        initialDate: completed ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) set(() => completed = d);
                    },
                  ),
                if (kind == 'task') ...[
                  choice(
                    'Проект',
                    selectedProject,
                    {for (final p in projects) p['id']: p['name'] as String},
                    (v) async {
                      final next = await repo.memberChoices(v);
                      if (!c.mounted) return;
                      set(() {
                        selectedProject = v;
                        members = next;
                        assignee = next.isEmpty ? null : next.first['id'];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: ValueKey('members-$selectedProject-$assignee'),
                    child: choice('Исполнитель', assignee, {
                      for (final u in members) u['id']: u['name'] as String,
                    }, (v) => set(() => assignee = v)),
                  ),
                  if (members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Сначала добавьте участника в проект на экране «Проекты».',
                      ),
                    ),
                  const SizedBox(height: 16),
                  choice(
                    'Приоритет',
                    priority,
                    priorities,
                    (v) => set(() => priority = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Дедлайн'),
                    subtitle: Text(dateText(deadline.millisecondsSinceEpoch)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: c,
                        initialDate: deadline,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) set(() => deadline = d);
                    },
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: TextStyle(color: Theme.of(c).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(c),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    set(() => busy = true);
                    try {
                      if (kind == 'user') {
                        await repo.saveUser(
                          name.text,
                          email.text,
                          id: row?['id'],
                        );
                      }
                      if (kind == 'project') {
                        await repo.saveProject(
                          name.text,
                          description.text,
                          status,
                          id: row?['id'],
                          completedAt: completed?.millisecondsSinceEpoch,
                        );
                      }
                      if (kind == 'task') {
                        if (actor == null) {
                          throw RuleException(
                            'Выберите действующего пользователя в верхней панели.',
                          );
                        }
                        if (selectedProject == null || assignee == null) {
                          throw RuleException(
                            'Выберите проект и его участника.',
                          );
                        }
                        await repo.saveTask(
                          id: row?['id'],
                          title: name.text,
                          description: description.text,
                          project: selectedProject!,
                          assignee: assignee!,
                          priority: priority,
                          status: status,
                          deadline: deadline,
                          actor: actor,
                        );
                      }
                      if (c.mounted) Navigator.pop(c);
                    } catch (e) {
                      if (c.mounted) {
                        set(() {
                          error = e.toString();
                          busy = false;
                        });
                      }
                    }
                  },
            child: Text(busy ? 'Сохранение…' : 'Сохранить'),
          ),
        ],
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  description.dispose();
  email.dispose();
}
