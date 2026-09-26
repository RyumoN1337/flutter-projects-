import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../data/products.dart';
import '../widgets/bottom_bar.dart';
import 'catalog_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  final List<int> favoriteIds = [];

  // Общее избранное для каталога и страницы избранного.
  void toggleFavorite(int id) {
    setState(() {
      if (favoriteIds.contains(id)) {
        favoriteIds.remove(id);
      } else {
        favoriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['home', 'catalog', 'favorites', 'profile'];
    final favoriteProducts =
        products.where((product) => favoriteIds.contains(product.id)).toList();
    final pages = [
      const HomePage(),
      CatalogPage(favoriteIds: favoriteIds, onToggle: toggleFavorite),
      FavoritesPage(products: favoriteProducts, onToggle: toggleFavorite),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(titles[currentIndex]))),
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
