import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showErrorToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.surface,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
