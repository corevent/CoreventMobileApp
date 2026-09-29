import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/auth_validation.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = checkPassword(password);
    final items = <(String, bool)>[
      ('8 caracteres ou mais', checks.length),
      ('Uma letra maiúscula', checks.uppercase),
      ('Uma letra minúscula', checks.lowercase),
      ('Um número', checks.number),
      ('Um símbolo', checks.symbol),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (label, met) in items)
              Semantics(
                label: '$label: ${met ? 'atendido' : 'pendente'}',
                child: Container(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: met
                        ? AppColors.orangeSoft
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        met
                            ? RemixIcons.check_line
                            : RemixIcons.checkbox_blank_circle_line,
                        size: 14,
                        color: met
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: met
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
