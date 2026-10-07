import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppDialogStyles {
  static const title = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const _actionText = TextStyle(
    inherit: false,
    fontSize: 14,
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w700,
  );

  static final action = TextButton.styleFrom(textStyle: _actionText);
  static final destructiveAction = TextButton.styleFrom(
    textStyle: _actionText,
    foregroundColor: AppColors.error,
  );
}
