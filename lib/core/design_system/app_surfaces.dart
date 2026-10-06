import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

/// Superfícies brancas se separam do canvas branco pelo contorno, sem sombra.
abstract final class AppSurfaces {
  static const outline = BorderSide(color: AppColors.backgroundSecondary);

  static const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
    side: outline,
  );

  static const cardDecoration = ShapeDecoration(
    color: AppColors.surface,
    shape: cardShape,
  );
}
