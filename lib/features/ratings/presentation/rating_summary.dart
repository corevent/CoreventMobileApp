import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/icon_label.dart';
import '../../../core/theme/app_colors.dart';

String ratingAverage(double value, {int? count}) {
  if (!value.isFinite || value <= 0) return 'Sem avaliações';
  final average = value.toStringAsFixed(1);
  return count != null && count >= 0 ? '$average ($count)' : average;
}

class EventAverageRating extends StatelessWidget {
  const EventAverageRating({
    super.key,
    required this.value,
    this.count,
    this.fontSize = 12,
    this.iconSize = 17,
  });

  final double value;
  final int? count;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final rated = value.isFinite && value > 0;
    final label = ratingAverage(value, count: count);
    return Semantics(
      label: rated
          ? 'Média das avaliações: ${value.toStringAsFixed(1)} de 5'
                '${count != null && count! >= 0 ? ', $count avaliações' : ''}'
          : label,
      excludeSemantics: true,
      child: CoreventIconLabel(
        icon: rated ? RemixIcons.star_fill : RemixIcons.star_line,
        iconColor: rated ? AppColors.primary : AppColors.textSecondary,
        iconSize: iconSize,
        label: label,
        style: TextStyle(
          height: 1.4,
          color: rated ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: fontSize,
          fontWeight: rated ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
