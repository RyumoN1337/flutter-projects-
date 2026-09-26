import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_text_styles.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class FavoritesPage extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<int> onToggle;

  const FavoritesPage(
      {super.key, required this.products, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Text(context.tr('empty_favorites'),
              textAlign: TextAlign.center, style: AppTextStyles.body),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
            product: product,
            isFavorite: true,
            onToggle: () => onToggle(product.id));
      },
    );
  }
}
