import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/screens.dart';
import 'presentation/state/feed_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    PostExplorer(
      repository: PostRepository(PostApi(DioClient.create()), PostCache(prefs)),
    ),
  );
}

class PostExplorer extends StatelessWidget {
  final PostRepository repository;
  const PostExplorer({super.key, required this.repository});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: repository),
      ChangeNotifierProvider(create: (_) => FeedState(repository)..refresh()),
    ],
    child: MaterialApp(
      title: 'Post Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF285BCE)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FC),
          centerTitle: false,
        ),
      ),
      home: const FeedScreen(),
    ),
  );
}
