import 'package:flutter/foundation.dart';

import '../model/models.dart';
import '../repository/task_repository.dart';

class AppState extends ChangeNotifier {
  final TaskRepository repository;
  AppState(this.repository);
  int section = 0, page = 0;
  int? actor, project, assignee;
  String search = '', sort = 'deadline';
  String? status, priority;
  bool ascending = true;
  TaskFilter get filter => TaskFilter(
    search: search,
    sort: sort,
    status: status,
    priority: priority,
    assignee: assignee,
    project: project,
    trash: section == 4,
    ascending: ascending,
    page: page,
  );
  void update(VoidCallback change, {bool resetPage = true}) {
    change();
    if (resetPage) page = 0;
    notifyListeners();
  }

  void showTasks({int? forProject, int? forUser}) => update(() {
    section = 2;
    project = forProject;
    assignee = forUser;
    search = '';
    status = null;
    priority = null;
  });
}
