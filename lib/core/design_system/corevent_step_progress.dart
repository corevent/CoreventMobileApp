import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

class CoreventStepProgress extends StatelessWidget {
  const CoreventStepProgress({
    super.key,
    required this.current,
    required this.total,
  });
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Etapa $current de $total',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etapa $current de $total',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(
            total,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.standard),
                curve: AppMotion.curve,
                height: 5,
                margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < current
                      ? AppColors.primary
                      : AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
