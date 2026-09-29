import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

enum CoreventNoticeType { error, success, info }

class CoreventNotice extends StatelessWidget {
  const CoreventNotice({
    super.key,
    required this.message,
    this.type = CoreventNoticeType.error,
  });

  final String? message;
  final CoreventNoticeType type;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final color = switch (type) {
      CoreventNoticeType.error => AppColors.error,
      CoreventNoticeType.success => AppColors.success,
      CoreventNoticeType.info => AppColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message!,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
