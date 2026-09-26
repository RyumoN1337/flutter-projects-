import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onToggle;

  const ProductCard(
      {super.key,
      required this.product,
      required this.isFavorite,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Image.asset(product.imagePath,
              width: 72.w,
              height: 72.w,
              fit: BoxFit.contain,
              semanticLabel: context.tr(product.nameKey)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(product.nameKey), style: AppTextStyles.body),
                SizedBox(height: 6.h),
                Text(
                    context.tr('price',
                        namedArgs: {'value': product.price.toString()}),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('favorite_${product.id}'),
            onPressed: onToggle,
            tooltip:
                context.tr(isFavorite ? 'remove_favorite' : 'add_favorite'),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: AppColors.favorite, size: 24.r),
          ),
        ],
      ),
    );
  }
}
