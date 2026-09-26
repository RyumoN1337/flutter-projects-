import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 11.sp,
      unselectedFontSize: 11.sp,
      iconSize: 24.r,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home), label: context.tr('home')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag), label: context.tr('catalog')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.favorite), label: context.tr('favorites')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person), label: context.tr('profile')),
      ],
    );
  }
}
