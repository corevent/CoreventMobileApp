import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

class CoreventPageHeader extends StatelessWidget {
  const CoreventPageHeader({
    super.key,
    required this.title,
    required this.description,
    this.onBack,
    this.backEnabled = true,
  });

  final String title;
  final String description;
  final VoidCallback? onBack;
  final bool backEnabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: backEnabled ? onBack : null,
              tooltip: 'Voltar',
              icon: const Icon(RemixIcons.arrow_left_line),
            ),
          Expanded(
            child: Image.asset(
              'assets/images/logo_corevent_full.png',
              height: 28,
              alignment: Alignment.center,
              semanticLabel: 'Corevent',
            ),
          ),
          if (onBack != null) const SizedBox(width: 48),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.standard),
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(title),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
    ],
  );
}
