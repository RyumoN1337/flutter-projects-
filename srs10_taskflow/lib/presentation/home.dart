import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../model/models.dart';
import '../state/app_state.dart';
import 'forms.dart';

class RowsView extends StatelessWidget {
  final Stream<List<DbRow>> stream;
  final Widget Function(List<DbRow>) builder;
  const RowsView({super.key, required this.stream, required this.builder});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<DbRow>>(
    stream: stream,
    builder: (c, s) {
      if (s.hasError) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Ошибка чтения: ${s.error}'),
        );
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return builder(s.data!);
    },
  );
}

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppState get s => widget.state;
  static const labels = ['Обзор', 'Проекты', 'Задачи', 'Участники', 'Корзина'];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.folder_outlined,
    Icons.task_alt,
    Icons.people_outline,
    Icons.delete_outline,
  ];
  Timer? refresh;
  @override
  void initState() {
    super.initState();
    refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    refresh?.cancel();
    super.dispose();
  }

  int requireActor() {
    if (s.actor == null) {
      throw RuleException(
        'Выберите действующего пользователя в верхней панели.',
      );
    }
    return s.actor!;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => LayoutBuilder(
      builder: (context, size) {
        final wide = size.maxWidth >= 850;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'TaskFlow',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            backgroundColor: Colors.white,
            actions: [
              SizedBox(
                width: wide ? 270 : 160,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RowsView(
                    stream: s.repository.users(),
                    builder: (users) => DropdownButton<int>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Выберите пользователя'),
                      value: users.any((u) => u['id'] == s.actor)
                          ? s.actor
                          : null,
                      items: users
                          .map(
                            (u) => DropdownMenuItem<int>(
                              value: u['id'],
                              child: Text(
                                u['name'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          s.update(() => s.actor = v, resetPage: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: s.section,
                  onDestinationSelected: (v) => s.update(() => s.section = v),
                  destinations: List.generate(
                    5,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  extended: true,
                  minExtendedWidth: 185,
                  selectedIndex: s.section,
                  onDestinationSelected: (v) => s.update(() => s.section = v),
                  destinations: List.generate(
                    5,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(labels[i]),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 24, 16, 12),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                labels[s.section],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.section == 0
                                    ? 'Ваши проекты, сроки и прогресс — в одном месте'
                                    : 'Локальное рабочее пространство • SQLite',
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          if (s.section > 0 && s.section < 4)
                            FilledButton.icon(
                              onPressed: () => editRecord(
                                context,
                                s.repository,
                                s.section == 1
                                    ? 'project'
                                    : s.section == 3
                                    ? 'user'
                                    : 'task',
                                actor: s.actor,
                                project: s.project,
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(
                                s.section == 1
                                    ? 'Новый проект'
                                    : s.section == 3
                                    ? 'Добавить пользователя'
                                    : 'Новая задача',
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: s.section == 0
                          ? dashboard()
                          : s.section == 1
                          ? projects()
                          : s.section == 3
                          ? users()
                          : tasks(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget empty(String text) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
  Widget dashboard() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      RowsView(
        stream: s.repository.totals(),
        builder: (r) {
          final x = r.first;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final e in {
                'projects': 'Проекты',
                'total': 'Все задачи',
                'done': 'Завершено',
                'pending': 'Незавершённые',
                'overdue': 'Просрочено',
              }.entries)
                SizedBox(
                  width: 180,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${x[e.key]}',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: e.key == 'overdue'
                                  ? Colors.deepOrange
                                  : const Color(0xff5265db),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Прогресс проектов',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      RowsView(
        stream: s.repository.projectStats(),
        builder: (rows) => rows.isEmpty
            ? empty('Создайте первый проект и добавьте участников.')
            : Column(
                children: rows
                    .map(
                      (r) => Card(
                        child: ListTile(
                          onTap: () => s.showTasks(forProject: r['id']),
                          title: Text(r['name']),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(
                              value: (r['percent'] as num).toDouble() / 100,
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          trailing: Text(
                            '${(r['percent'] as num).toStringAsFixed(0)}%\n${r['done']} / ${r['total']}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Задачи по приоритетам',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      RowsView(
        stream: s.repository.priorityStats(),
        builder: (rows) => Wrap(
          spacing: 8,
          children: priorities.entries.map((e) {
            final r = rows.where((r) => r['priority'] == e.key);
            return Chip(
              label: Text('${e.value}: ${r.isEmpty ? 0 : r.first['n']}'),
            );
          }).toList(),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Нагрузка участников',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      RowsView(
        stream: s.repository.assigneeStats(),
        builder: (rows) => Column(
          children: rows
              .map(
                (r) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(r['name']),
                    trailing: Text('${r['n']} задач'),
                    onTap: () => s.showTasks(forUser: r['id']),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Незавершённые: ожидающие и в работе. Отменённые не входят в этот показатель. Корзина исключена из статистики.',
        ),
      ),
    ],
  );
  Widget users() => RowsView(
    stream: s.repository.users(),
    builder: (rows) => rows.isEmpty
        ? empty('Добавьте пользователя, затем выберите его в верхней панели.')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (c, i) {
              final u = rows[i];
              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(u['name']),
                  subtitle: Text(
                    '${u['email']}\nРегистрация: ${dateText(u['registered_at'])}',
                  ),
                  onTap: () => s.showTasks(forUser: u['id']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await editRecord(context, s.repository, 'user', row: u);
                        return;
                      }
                      if (v == 'delete' &&
                          mounted &&
                          await confirm(
                            context,
                            'Удалить пользователя? Незавершённые задачи блокируют удаление.',
                          )) {
                        if (!mounted) return;
                        await runAction(
                          context,
                          () => s.repository.deleteUser(u['id']),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Редактировать'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                ),
              );
            },
          ),
  );
  Widget projects() => RowsView(
    stream: s.repository.projects(),
    builder: (rows) => rows.isEmpty
        ? empty(
            'Создайте проект, добавьте участников и назначьте первую задачу.',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (c, i) {
              final p = rows[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${p['description']}\n${projectStatuses[p['status']]} • ${dateText(p['created_at'])}\nЗавершение: ${dateText(p['completed_at'])}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await editRecord(
                                context,
                                s.repository,
                                'project',
                                row: p,
                              );
                              return;
                            }
                            if (v == 'delete' &&
                                await confirm(
                                  context,
                                  'Удалить проект и все его задачи, комментарии, вложения и историю безвозвратно?',
                                )) {
                              if (!mounted) return;
                              await runAction(
                                context,
                                () => s.repository.deleteProject(p['id']),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Редактировать'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить'),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => s.showTasks(forProject: p['id']),
                            icon: const Icon(Icons.task_alt),
                            label: const Text('Задачи'),
                          ),
                          TextButton.icon(
                            onPressed: () => members(p),
                            icon: const Icon(Icons.group_outlined),
                            label: const Text('Участники и роли'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
  Future<void> members(DbRow project) async {
    final all = await s.repository.users().first;
    if (!mounted) return;
    int? user = all.isEmpty ? null : all.first['id'];
    String role = 'Member';
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('Участники: ${project['name']}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  choice('Пользователь', user, {
                    for (final u in all) u['id']: u['name'] as String,
                  }, (v) => set(() => user = v)),
                  const SizedBox(height: 12),
                  choice('Роль', role, roles, (v) => set(() => role = v)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: user == null
                        ? null
                        : () => runAction(
                            c,
                            () => s.repository.addMember(
                              project['id'],
                              user!,
                              role,
                            ),
                          ),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                  RowsView(
                    stream: s.repository.members(project['id']),
                    builder: (rows) => Column(
                      children: rows
                          .map(
                            (m) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(m['name']),
                              subtitle: Text(m['role']),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) => runAction(
                                  c,
                                  () => v == 'remove'
                                      ? s.repository.removeMember(
                                          project['id'],
                                          m['user_id'],
                                        )
                                      : s.repository.changeRole(
                                          project['id'],
                                          m['user_id'],
                                          v,
                                        ),
                                ),
                                itemBuilder: (_) => [
                                  ...roles.keys.map(
                                    (r) =>
                                        PopupMenuItem(value: r, child: Text(r)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Удалить участника'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
  }

  Widget tasks() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextFormField(
              key: ValueKey('search-${s.section}-${s.project}-${s.assignee}'),
              initialValue: s.search,
              onChanged: (v) => s.update(() => s.search = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск по названию и описанию',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  filterChoice(
                    'Статус',
                    s.status,
                    statuses,
                    (v) => s.update(() => s.status = v),
                  ),
                  filterChoice(
                    'Приоритет',
                    s.priority,
                    priorities,
                    (v) => s.update(() => s.priority = v),
                  ),
                  SizedBox(
                    width: 190,
                    child: RowsView(
                      stream: s.repository.users(),
                      builder: (r) => filterChoice('Исполнитель', s.assignee, {
                        for (final u in r) u['id']: u['name'] as String,
                      }, (v) => s.update(() => s.assignee = v)),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: RowsView(
                      stream: s.repository.projects(),
                      builder: (r) => filterChoice('Проект', s.project, {
                        for (final p in r) p['id']: p['name'] as String,
                      }, (v) => s.update(() => s.project = v)),
                    ),
                  ),
                  SizedBox(
                    width: 185,
                    child: choice('Сортировать', s.sort, const {
                      'deadline': 'По дедлайну',
                      'created_at': 'По созданию',
                    }, (v) => s.update(() => s.sort = v)),
                  ),
                  IconButton(
                    tooltip: 'Изменить направление',
                    onPressed: () => s.update(() => s.ascending = !s.ascending),
                    icon: Icon(
                      s.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: RowsView(
          stream: s.repository.tasks(s.filter),
          builder: (rows) => rows.isEmpty
              ? empty(
                  s.section == 4 ? 'Корзина пуста' : 'Задачи не найдены. Измените фильтры или создайте задачу.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rows.length,
                  itemBuilder: (c, i) {
                    final t = rows[i];
                    final overdue =
                        t['deadline'] < day(DateTime.now()) &&
                        ['todo', 'inProgress'].contains(t['status']);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          t['status'] == 'done'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: t['status'] == 'done'
                              ? Colors.teal
                              : const Color(0xff5265db),
                        ),
                        title: Text(
                          t['title'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${t['project_name']} • ${t['assignee_name'] ?? 'Удалённый участник'}\n${statuses[t['status']]} · ${priorities[t['priority']]} · ${dateText(t['deadline'])}',
                          style: TextStyle(
                            color: overdue ? Colors.deepOrange : null,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => details(t['id']),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
        ),
      ),
      RowsView(
        stream: s.repository.taskCount(s.filter),
        builder: (r) {
          final n = r.first['n'] as int;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Предыдущая страница',
                onPressed: s.page == 0
                    ? null
                    : () => s.update(() => s.page--, resetPage: false),
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Text(
                  'Страница ${s.page + 1} • Всего: $n',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'Следующая страница',
                onPressed: (s.page + 1) * 25 >= n
                    ? null
                    : () => s.update(() => s.page++, resetPage: false),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          );
        },
      ),
    ],
  );
  Widget filterChoice(
    String label,
    dynamic value,
    Map<dynamic, String> options,
    ValueChanged<dynamic> change,
  ) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: SizedBox(
      width: 180,
      child: KeyedSubtree(
        key: ValueKey('$label-$value'),
        child: choice(label, value, options, change, nullable: true),
      ),
    ),
  );
  Future<void> details(int id) async {
    final comment = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: RowsView(
            stream: s.repository.taskDetails(id),
            builder: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Задача удалена. Закрыть'),
                  ),
                );
              }
              final t = rows.first;
              final trash = t['deleted_at'] != null;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t['title'],
                            style: Theme.of(c).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Закрыть',
                          onPressed: () => Navigator.pop(c),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      '${t['project_name']} • ${t['assignee_name'] ?? 'Исполнитель удалён'}',
                    ),
                    const SizedBox(height: 12),
                    Text(t['description']),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(label: Text(statuses[t['status']]!)),
                        Chip(label: Text(priorities[t['priority']]!)),
                        Chip(label: Text('Срок: ${dateText(t['deadline'])}')),
                      ],
                    ),
                    Text(
                      'Создана: ${timeText(t['created_at'])}\nИзменена: ${timeText(t['updated_at'])}',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => editRecord(
                            c,
                            s.repository,
                            'task',
                            row: t,
                            actor: s.actor,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Изменить'),
                        ),
                        if (!trash) ...[
                          PopupMenuButton<String>(
                            tooltip: 'Изменить статус',
                            onSelected: (v) => runAction(
                              c,
                              () =>
                                  s.repository.setStatus(id, v, requireActor()),
                            ),
                            itemBuilder: (_) => statuses.entries
                                .map(
                                  (e) => PopupMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Изменить статус'),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => runAction(
                              c,
                              () => s.repository.undoStatus(id, requireActor()),
                            ),
                            icon: const Icon(Icons.undo),
                            label: const Text('Отменить статус'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                runAction(c, () => s.repository.trashTask(id)),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('В корзину'),
                          ),
                        ],
                        if (trash) ...[
                          TextButton.icon(
                            onPressed: () => runAction(
                              c,
                              () => s.repository.restoreTask(id),
                            ),
                            icon: const Icon(Icons.restore),
                            label: const Text('Восстановить'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await confirm(
                                c,
                                'Безвозвратно удалить задачу со всеми комментариями и историей?',
                              )) {
                                if (!c.mounted) return;
                                await runAction(
                                  c,
                                  () => s.repository.purgeTask(id),
                                );
                              }
                            },
                            child: const Text('Удалить навсегда'),
                          ),
                        ],
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Комментарии',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: comment,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Новый комментарий',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => runAction(c, () async {
                        await s.repository.addComment(
                          id,
                          requireActor(),
                          comment.text,
                        );
                        comment.clear();
                      }),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Отправить'),
                    ),
                    RowsView(
                      stream: s.repository.comments(id),
                      builder: (r) => Column(
                        children: r
                            .map(
                              (x) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(x['body']),
                                subtitle: Text(
                                  '${x['author_name']} • ${timeText(x['created_at'])}',
                                ),
                                trailing: x['author_id'] == s.actor
                                    ? IconButton(
                                        tooltip: 'Удалить свой комментарий',
                                        onPressed: () => runAction(
                                          c,
                                          () => s.repository.deleteComment(
                                            x['id'],
                                            requireActor(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const Divider(),
                    const Text(
                      'Вложения',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => runAction(c, () async {
                        final result = await FilePicker.pickFile();
                        if (result != null && result.path != null) {
                          await s.repository.attachFile(id, result.path!);
                        }
                      }),
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Прикрепить файл'),
                    ),
                    RowsView(
                      stream: s.repository.attachments(id),
                      builder: (r) => Column(
                        children: r
                            .map(
                              (x) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.insert_drive_file_outlined,
                                ),
                                title: Text(x['name']),
                                subtitle: Text(
                                  '${dateText(x['created_at'])}\n${x['local_path']}',
                                ),
                                onTap: () => runAction(c, () async {
                                  final result = await OpenFilex.open(
                                    x['local_path'],
                                  );
                                  if (result.type != ResultType.done) {
                                    throw RuleException(result.message);
                                  }
                                }),
                                trailing: IconButton(
                                  tooltip: 'Удалить вложение',
                                  onPressed: () => runAction(
                                    c,
                                    () =>
                                        s.repository.deleteAttachment(x['id']),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const Divider(),
                    const Text(
                      'История изменений',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RowsView(
                      stream: s.repository.history(id),
                      builder: (r) => Column(
                        children: r
                            .map(
                              (x) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history),
                                title: Text(
                                  x['kind'] == 'assignment'
                                      ? 'Переназначение: #${x['old_assignee_id'] ?? '—'} → #${x['new_assignee_id']}'
                                      : '${x['kind'] == 'created'
                                            ? 'Создание'
                                            : x['kind'] == 'undo'
                                            ? 'Отмена'
                                            : 'Статус'}: ${statuses[x['old_status']] ?? '—'} → ${statuses[x['new_status']]}${x['undone'] == 1 ? ' (отменено)' : ''}',
                                ),
                                subtitle: Text(
                                  '${x['actor_name']} • ${timeText(x['created_at'])}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    comment.dispose();
  }
}
