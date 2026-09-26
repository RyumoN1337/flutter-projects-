import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(const MyApp());

// Общая функция для коротких уведомлений.
void showMessage(String message) {
  Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой каталог',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> items = List.generate(
    10,
    (index) => 'Товар №${index + 1}',
  );
  final List<Color> colors = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
  ];
  final List<bool> selected = List.filled(6, false);
  bool remindersEnabled = true;

  void openAddDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (name) {
          setState(() {
            items.add(name);
          });
          showMessage('Добавлено: $name');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мой каталог'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Список', icon: Icon(Icons.list)),
              Tab(text: 'Сетка', icon: Icon(Icons.grid_view)),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo),
                child: Text(
                  'Мой каталог',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Главная'),
                // Главная уже находится под Drawer: закрываем меню.
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Профиль'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Настройки'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => SettingsScreen(
                        initialValue: remindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            remindersEnabled = value;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Выход'),
                onTap: () {
                  Navigator.pop(context);
                  showMessage('Выход из аккаунта');
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.style),
                    label: const Text('Карточки'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const CardsScreen(),
                        ),
                      );
                    },
                  ),
                  OutlinedButton(
                    onPressed: () => showMessage('Hello, Flutter!'),
                    child: const Text('Показать приветствие'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_bag,
                            color: Colors.indigo,
                          ),
                          title: Text(items[index]),
                          subtitle: Text('Описание товара №${index + 1}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              showMessage('Вы выбрали: ${items[index]}'),
                        ),
                      );
                    },
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: colors.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      return Material(
                        color: selected[index] ? Colors.green : colors[index],
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selected[index] = !selected[index];
                            });
                          },
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (tabContext) => FloatingActionButton(
            tooltip: 'Добавить элемент',
            onPressed: () {
              DefaultTabController.of(tabContext).animateTo(0);
              openAddDialog();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// Контроллер принадлежит диалогу и освобождается при его закрытии.
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key, required this.onAdd});
  final ValueChanged<String> onAdd;
  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void addItem() {
    final name = controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        error = 'Введите название';
      });
      return;
    }
    widget.onAdd(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый элемент'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(labelText: 'Название', errorText: error),
        onSubmitted: (value) => addItem(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(onPressed: addItem, child: const Text('Добавить')),
      ],
    );
  }
}

// Простой класс объединяет данные одного товара.
class Product {
  const Product(this.name, this.description, this.details, this.image);
  final String name;
  final String description;
  final String details;
  final String image;
}

const List<Product> products = [
  Product(
    'Смартфон',
    'Для общения и учёбы.',
    'Учебный пример смартфона: экран 6,5 дюйма, память 128 ГБ. '
        'Подходит для звонков, фотографий и просмотра учебных материалов.',
    'assets/images/phone.png',
  ),
  Product(
    'Ноутбук',
    'Помощник в программировании.',
    'Учебный пример ноутбука: экран 15,6 дюйма, 16 ГБ оперативной памяти. '
        'На нём удобно писать код, готовить презентации и изучать Flutter.',
    'assets/images/laptop.png',
  ),
  Product(
    'Наушники',
    'Для музыки и видеолекций.',
    'Учебный пример беспроводных наушников с микрофоном. '
        'Их можно использовать для онлайн-занятий и разговоров.',
    'assets/images/headphones.png',
  ),
  Product(
    'Часы',
    'Время всегда под рукой.',
    'Учебный пример умных часов. Они показывают время, считают шаги '
        'и помогают следить за повседневной активностью.',
    'assets/images/watch.png',
  ),
];

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карточки')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  product.image,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(product.description),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          child: const Text('Подробнее'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    DetailsScreen(product: product),
                              ),
                            );
                          },
                        ),
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
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(product.image),
          ),
          const SizedBox(height: 20),
          Text(product.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            product.details,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              child: Icon(Icons.person, size: 56),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Студент Flutter',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text('student@example.com', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'Изучаю основные виджеты Flutter.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool remindersEnabled;

  @override
  void initState() {
    super.initState();
    remindersEnabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Учебные напоминания'),
            subtitle: Text(remindersEnabled ? 'Включены' : 'Выключены'),
            value: remindersEnabled,
            onChanged: (value) {
              setState(() {
                remindersEnabled = value;
              });
              widget.onChanged(value);
              showMessage('Настройки сохранены');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Учебная настройка сохраняется до закрытия приложения. '
            'Системные напоминания не отправляются.',
          ),
        ],
      ),
    );
  }
}
