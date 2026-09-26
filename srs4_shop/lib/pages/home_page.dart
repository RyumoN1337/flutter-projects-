import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget infoCard(
      BuildContext context, IconData icon, String title, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 40.r),
          SizedBox(height: 12.h),
          Text(context.tr(title),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(context.tr(text), style: AppTextStyles.caption),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      children: [
        Text(context.tr('welcome_title'), style: AppTextStyles.title),
        SizedBox(height: 8.h),
        Text(context.tr('welcome_text'), style: AppTextStyles.body),
        infoCard(context, Icons.shopping_bag_outlined, 'card_catalog',
            'card_catalog_text'),
        infoCard(context, Icons.favorite_border, 'card_favorites',
            'card_favorites_text'),
      ],
    );
  }
}
