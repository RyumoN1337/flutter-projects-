import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(title)),
        content: Text(context.tr(message)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('close')))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      children: [
        Center(
            child: CircleAvatar(
          radius: 40.r,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 48.r, color: AppColors.white),
        )),
        SizedBox(height: 12.h),
        Text(context.tr('user_name'),
            textAlign: TextAlign.center, style: AppTextStyles.title),
        SizedBox(height: 24.h),
        Text(context.tr('settings'), style: AppTextStyles.body),
        SizedBox(height: 8.h),
        Text(context.tr('language'), style: AppTextStyles.caption),
        // Wrap переносит кнопки, если на экране мало места.
        Wrap(
          spacing: 8.w,
          children: [
            ChoiceChip(
                label: Text(context.tr('russian')),
                selected: context.locale.languageCode == 'ru',
                onSelected: (_) async {
                  await context.setLocale(const Locale('ru'));
                }),
            ChoiceChip(
                label: Text(context.tr('english')),
                selected: context.locale.languageCode == 'en',
                onSelected: (_) async {
                  await context.setLocale(const Locale('en'));
                }),
          ],
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(Icons.help_outline, size: 24.r, color: AppColors.primary),
          title: Text(context.tr('help'), style: AppTextStyles.body),
          onTap: () => showInfo(context, 'help', 'help_text'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Icon(Icons.info_outline, size: 24.r, color: AppColors.primary),
          title: Text(context.tr('about'), style: AppTextStyles.body),
          onTap: () => showInfo(context, 'about', 'about_text'),
        ),
        SizedBox(height: 12.h),
        Text(context.tr('version'), style: AppTextStyles.caption),
      ],
    );
  }
}
