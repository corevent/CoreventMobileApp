import 'package:flutter/material.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/theme/app_colors.dart';

Widget pageBound(Widget child, {double top = 0}) => Padding(
  padding: EdgeInsets.fromLTRB(20, top, 20, 0),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: SizedBox(width: double.infinity, child: child),
    ),
  ),
);

class FeedSectionTitle extends StatelessWidget {
  const FeedSectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    ],
  );
}

class FeedMessage extends StatelessWidget {
  const FeedMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 42, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.start,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        CoreventTextAction(label: action, onPressed: onAction),
      ],
    ),
  );
}

class FeedStatus extends StatelessWidget {
  const FeedStatus(
    this.message, {
    super.key,
    this.loading = false,
    this.onRetry,
  });
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.fromBorderSide(AppSurfaces.outline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (onRetry != null)
            CoreventTextAction(label: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    ),
  );
}

class FeedReveal extends StatelessWidget {
  const FeedReveal({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.duration(context, AppMotion.standard),
    curve: AppMotion.curve,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * 8),
        child: child,
      ),
    ),
    child: child,
  );
}
