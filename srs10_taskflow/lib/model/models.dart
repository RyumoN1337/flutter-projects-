typedef DbRow = Map<String, dynamic>;

const statuses = {
  'todo': 'Ожидает',
  'inProgress': 'В работе',
  'done': 'Завершена',
  'cancelled': 'Отменена',
};
const priorities = {
  'low': 'Низкий',
  'medium': 'Средний',
  'high': 'Высокий',
  'critical': 'Критический',
};
const projectStatuses = {
  'active': 'Активный',
  'completed': 'Завершённый',
  'archived': 'Архивный',
};
const roles = {'Owner': 'Owner', 'Admin': 'Admin', 'Member': 'Member'};
int day(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
String dateText(dynamic value) {
  if (value == null) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(value as int);
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

String timeText(dynamic value) {
  final d = DateTime.fromMillisecondsSinceEpoch(value as int);
  return '${dateText(value)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
}

class RuleException implements Exception {
  final String message;
  RuleException(this.message);
  @override
  String toString() => message;
}

class TaskFilter {
  final String search, sort;
  final String? status, priority;
  final int? assignee, project;
  final bool trash, ascending;
  final int page, pageSize;
  const TaskFilter({
    this.search = '',
    this.sort = 'deadline',
    this.status,
    this.priority,
    this.assignee,
    this.project,
    this.trash = false,
    this.ascending = true,
    this.page = 0,
    this.pageSize = 25,
  });
}
