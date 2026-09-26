import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Геттер пересчитывает размер при изменении размеров экрана.
  // const здесь не подходит: значение .sp вычисляется во время работы.
  static TextStyle get title => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => TextStyle(
        fontSize: 16.sp,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 14.sp,
        color: AppColors.textSecondary,
      );
}
