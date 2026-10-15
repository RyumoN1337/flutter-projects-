import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

// ───────────────────────── СОБСТВЕННАЯ ТЕМА ─────────────────────────
class AppTheme {
  static ThemeData build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );
    return base.copyWith(
      // Изменение шрифта (Google Fonts). Локальный шрифт: см. README
      textTheme: GoogleFonts.robotoSlabTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Класс для передачи параметров через arguments
class ProfileArgs {
  final String name;
  final int age;
  const ProfileArgs(this.name, this.age);
}

// ───────────────────────── КОРНЕВОЙ STATEFUL ВИДЖЕТ ─────────────────────────
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleTheme() => setState(() {
        _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Course App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: _mode,
      // Именованные маршруты
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(onToggleTheme: _toggleTheme),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// ───────────────────────── ГЛАВНЫЙ ЭКРАН (IndexedStack) ─────────────────────────
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme; // параметр через конструктор
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _tabs = const [
    BasicsTab(),
    ListTab(),
    GridTab(),
    PageTab(),
    StackTab(),
  ];

  final _titles = const ['Основы', 'ListView', 'GridView', 'PageView', 'Stack'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Сменить тему',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      // IndexedStack хранит состояние всех вкладок, показывая одну
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.widgets), label: 'Основы'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Список'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Сетка'),
          NavigationDestination(icon: Icon(Icons.view_carousel), label: 'Pages'),
          NavigationDestination(icon: Icon(Icons.layers), label: 'Stack'),
        ],
      ),
    );
  }
}

// ───────────────────────── 1. ОСНОВЫ ─────────────────────────
class BasicsTab extends StatelessWidget {
  const BasicsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stateless виджет', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const InfoCard(title: 'Я не меняюсь', icon: Icons.lock),
          const SizedBox(height: 24),
          Text('Stateful виджет', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const CounterWidget(),
          const SizedBox(height: 24),
          Text('Container + BoxDecoration',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.indigo],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'Градиент, рамка, тень',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(height: 24),
          Text('Row и Column', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: const [
                  Icon(Icons.home, size: 40),
                  Text('Дом'),
                ],
              ),
              Column(
                children: const [
                  Icon(Icons.work, size: 40),
                  Text('Работа'),
                ],
              ),
              Column(
                children: const [
                  Icon(Icons.school, size: 40),
                  Text('Учёба'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Изображение из assets',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/logo.png', width: 140),
            ),
          ),
          const SizedBox(height: 24),
          Text('Шрифты', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Lobster', style: GoogleFonts.lobster(fontSize: 28)),
          Text('Pacifico', style: GoogleFonts.pacifico(fontSize: 28)),
          Text('Roboto Slab (из темы)',
              style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

// Stateless виджет с параметрами в конструкторе
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  const InfoCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(title)),
    );
  }
}

// Stateful виджет
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Нажми'),
        ),
        const SizedBox(width: 16),
        Text('Счётчик: $_count', style: const TextStyle(fontSize: 20)),
      ],
    );
  }
}

// ───────────────────────── 2. LISTVIEW + NAVIGATOR ─────────────────────────
class ListTab extends StatelessWidget {
  const ListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 21,
      itemBuilder: (context, i) {
        // Первый элемент — переход по именованному маршруту с arguments
        if (i == 0) {
          return ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Профиль (pushNamed + arguments)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(
              context,
              '/profile',
              arguments: const ProfileArgs('Анна', 21),
            ),
          );
        }
        return ListTile(
          leading: CircleAvatar(child: Text('$i')),
          title: Text('Элемент №$i'),
          subtitle: const Text('Нажмите — анонимный маршрут (push)'),
          onTap: () async {
            // Анонимный маршрут + параметры в конструкторе + результат из pop
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(title: 'Элемент №$i', number: i),
              ),
            );
            if (result != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(result)));
            }
          },
        );
      },
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String title;
  final int number;
  const DetailScreen({super.key, required this.title, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Вы открыли элемент $number',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            // Картинка из сети
            Image.network(
              'https://picsum.photos/seed/$number/300/200',
              width: 300,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'Вернулись из №$number'),
              child: const Text('Назад (pop)'),
            ),
          ],
        ),
      ),
    );
  }
}

// Экран, получающий данные через arguments маршрута
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ProfileArgs;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            const SizedBox(height: 16),
            Text('Имя: ${args.name}',
                style: Theme.of(context).textTheme.headlineSmall),
            Text('Возраст: ${args.age}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 3. GRIDVIEW ─────────────────────────
class GridTab extends StatelessWidget {
  const GridTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: i.isEven ? scheme.primaryContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 40),
            const SizedBox(height: 6),
            Text('Ячейка ${i + 1}'),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 4. PAGEVIEW ─────────────────────────
class PageTab extends StatefulWidget {
  const PageTab({super.key});

  @override
  State<PageTab> createState() => _PageTabState();
}

class _PageTabState extends State<PageTab> {
  final _controller = PageController();
  int _page = 0;

  final _colors = const [Colors.teal, Colors.orange, Colors.purple];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _colors.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _colors[i],
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                'Страница ${i + 1}\n(листайте вбок)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _colors.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              width: _page == i ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: _page == i ? _colors[i] : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ───────────────────────── 5. STACK / POSITIONED / INDEXEDSTACK ─────────────────────────
class StackTab extends StatefulWidget {
  const StackTab({super.key});

  @override
  State<StackTab> createState() => _StackTabState();
}

class _StackTabState extends State<StackTab> {
  int _layer = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Stack + Positioned',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Container(color: Colors.teal.shade200),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(width: 100, height: 100, color: Colors.red),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child:
                      Container(width: 120, height: 80, color: Colors.amber),
                ),
                const Positioned(
                  top: 70,
                  left: 70,
                  child: Icon(Icons.star, size: 64, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('IndexedStack', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          IndexedStack(
            index: _layer,
            children: const [
              Icon(Icons.looks_one, size: 80, color: Colors.red),
              Icon(Icons.looks_two, size: 80, color: Colors.green),
              Icon(Icons.looks_3, size: 80, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() => _layer = (_layer + 1) % 3),
            child: const Text('Следующий слой'),
          ),
        ],
      ),
    );
  }
}
