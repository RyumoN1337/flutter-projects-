import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/products.dart';
import '../widgets/product_card.dart';

class CatalogPage extends StatelessWidget {
  final List<int> favoriteIds;
  final ValueChanged<int> onToggle;

  const CatalogPage(
      {super.key, required this.favoriteIds, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          isFavorite: favoriteIds.contains(product.id),
          onToggle: () => onToggle(product.id),
        );
      },
    );
  }
}
