import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/models.dart';
import '../../data/repositories/post_repository.dart';
import '../state/feed_state.dart';

class Notice extends StatelessWidget {
  final String text;
  final VoidCallback? retry;
  const Notice(this.text, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Повторить')),
      ],
    ),
  );
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final search = TextEditingController();
  final scroll = ScrollController();
  List<User> users = [];
  String? usersError;
  bool usersLoading = true;
  @override
  void initState() {
    super.initState();
    loadUsers();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 350 &&
          context.read<FeedState>().pageError == null) {
        context.read<FeedState>().next();
      }
    });
  }

  Future<void> loadUsers() async {
    final repo = context.read<PostRepository>();
    users = repo.cachedUsers();
    setState(() {
      usersLoading = true;
      usersError = null;
    });
    try {
      final result = await repo.users();
      if (mounted) setState(() => users = result);
    } catch (e) {
      if (mounted) setState(() => usersError = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => usersLoading = false);
    }
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeedState>();
    final visible = state.visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: state.refreshing ? null : () => state.refresh(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CreateScreen()),
          );
          if (context.mounted) context.read<FeedState>().syncLocals();
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать пост'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: () => state.refresh(),
            child: ListView(
              controller: scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Text(
                  'Исследуйте. Читайте. Создавайте.',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Посты сообщества • JSONPlaceholder'),
                const SizedBox(height: 24),
                TextField(
                  controller: search,
                  onChanged: state.search,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по заголовку',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Поиск и сортировка — среди загруженных постов',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 290,
                      child: DropdownButtonFormField<int>(
                        initialValue: state.author ?? 0,
                        key: ValueKey(state.author),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Автор'),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Все авторы'),
                          ),
                          ...users.map(
                            (u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(
                                '${u.id} · ${u.name}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (id) => state.filter(id == 0 ? null : id),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.sort,
                      icon: Icon(state.descending ? Icons.south : Icons.north),
                      label: const Text('По ID'),
                    ),
                    TextButton(
                      onPressed: () {
                        search.clear();
                        state.reset();
                      },
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
                if (usersLoading) const LinearProgressIndicator(),
                if (usersError != null)
                  Notice(
                    'Авторы: $usersError${users.isNotEmpty ? ' Используется кэш авторов.' : ''}',
                    retry: loadUsers,
                  ),
                const SizedBox(height: 16),
                Text(
                  'ПОСТЫ · ${visible.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                if (state.cached)
                  const Notice('Показаны сохранённые данные из кэша.'),
                if (state.refreshing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (state.error != null)
                  Notice(state.error!.message, retry: () => state.refresh()),
                if (visible.isEmpty && !state.refreshing)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Посты не найдены. Измените поиск или фильтр.',
                      ),
                    ),
                  ),
                ...visible.map(
                  (p) => Card(
                    margin: const EdgeInsets.only(top: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: CircleAvatar(child: Text('${p.id}')),
                      title: Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Автор ${p.userId}${p.local ? ' · создан локально' : ''}\n${p.body}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(post: p),
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (state.pageError != null)
                  Notice(state.pageError!.message, retry: state.next),
                if (state.hasMore &&
                    !state.refreshing &&
                    !state.loadingMore &&
                    state.error == null &&
                    state.pageError == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: state.next,
                      child: const Text('Загрузить ещё'),
                    ),
                  ),
                if (!state.hasMore)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Все посты загружены')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Post post;
  List<Comment> comments = [];
  bool loading = true, cached = false;
  String? error;
  @override
  void initState() {
    super.initState();
    post = widget.post;
    load();
  }

  Future<void> load() async {
    if (post.local) {
      setState(() => loading = false);
      return;
    }
    final repo = context.read<PostRepository>();
    post =
        repo.cached(
          'post_${post.id}',
          (j) => Post.fromJson(Map<String, dynamic>.from(j)),
        ) ??
        post;
    comments =
        repo.cached(
          'comments_${post.id}',
          (j) => (j as List)
              .map((c) => Comment.fromJson(Map<String, dynamic>.from(c)))
              .toList(),
        ) ??
        comments;
    setState(() {
      loading = true;
      cached = true;
      error = null;
    });
    try {
      final result = await Future.wait<Object>([
        repo.post(post.id),
        repo.comments(post.id),
      ]);
      if (mounted) {
        setState(() {
          post = result[0] as Post;
          comments = result[1] as List<Comment>;
          cached = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Пост #${post.id}')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (loading) const LinearProgressIndicator(),
              if (cached)
                const Notice(
                  'Показаны сохранённые данные. Обновление доступно при подключении.',
                ),
              if (error != null) Notice(error!, retry: load),
              if (post.local)
                const Notice(
                  'Создан локально. JSONPlaceholder вернул этот объект, но не сохраняет его на сервере.',
                ),
              Text(
                'АВТОР ${post.userId}',
                style: const TextStyle(color: Colors.indigo, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                post.body,
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
              const SizedBox(height: 32),
              Text(
                'Комментарии · ${comments.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (comments.isEmpty && !loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    post.local
                        ? 'Для локального поста серверные комментарии недоступны.'
                        : 'Комментариев пока нет.',
                  ),
                ),
              ...comments.map(
                (c) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (c.email != null)
                          Text(
                            c.email!,
                            style: const TextStyle(color: Colors.indigo),
                          ),
                        const SizedBox(height: 10),
                        Text(c.body),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(), body = TextEditingController();
  List<User> users = [];
  int? userId;
  bool loading = true, sending = false, cached = false;
  String? error;
  Post? created;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final repo = context.read<PostRepository>();
    users = repo.cachedUsers();
    setState(() {
      loading = true;
      error = null;
      cached = users.isNotEmpty;
    });
    try {
      final result = await repo.users();
      if (mounted) {
        setState(() {
          users = result;
          cached = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? validate(String? value, int min, int max) {
    final count = value?.trim().length ?? 0;
    return count < min || count > max
        ? 'Введите от $min до $max символов'
        : null;
  }

  Future<void> submit() async {
    if (sending || !form.currentState!.validate()) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final result = await context.read<PostRepository>().create(
        title.text,
        body.text,
        userId!,
      );
      if (mounted) {
        context.read<FeedState>().syncLocals();
        setState(() => created = result);
      }
    } catch (e) {
      if (mounted) setState(() => error = AppException.from(e).message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Создать пост')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Notice(
              'Тестовый API: созданный пост сохраняется только в локальном списке приложения.',
            ),
            if (loading || sending) const LinearProgressIndicator(),
            if (cached) const Notice('Список авторов загружен из кэша.'),
            if (error != null)
              Notice(error!, retry: users.isEmpty ? load : null),
            if (!loading && users.isEmpty)
              const Notice('Нет доступных авторов. Повторите загрузку списка.'),
            if (created != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text(
                'Сервер вернул пост #${created!.id}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text('Создан локально'),
              const SizedBox(height: 16),
              Text('Автор: ${created!.userId}'),
              Text(
                created!.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(created!.body),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('К списку постов'),
              ),
            ] else
              Form(
                key: form,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: title,
                      enabled: !sending,
                      maxLength: 100,
                      validator: (v) => validate(v, 5, 100),
                      decoration: const InputDecoration(
                        labelText: 'Заголовок',
                        helperText: 'От 5 до 100 символов',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: body,
                      enabled: !sending,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 1000,
                      validator: (v) => validate(v, 10, 1000),
                      decoration: const InputDecoration(
                        labelText: 'Текст поста',
                        helperText: 'От 10 до 1000 символов',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Автор'),
                      items: users
                          .map(
                            (u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                      onChanged: sending ? null : (v) => userId = v,
                      validator: (v) => v == null ? 'Выберите автора' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: sending || users.isEmpty ? null : submit,
                        icon: const Icon(Icons.send),
                        label: Text(
                          sending ? 'Отправка…' : 'Опубликовать тестовый пост',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

