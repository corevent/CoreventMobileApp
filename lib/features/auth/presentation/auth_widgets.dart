import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/corevent_field.dart';
import '../../../core/design_system/corevent_notice.dart';
import '../../../core/design_system/corevent_page_header.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.onBack,
    this.busy = false,
  });
  final String title;
  final String description;
  final List<Widget> children;
  final VoidCallback? onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy) onBack?.call();
    },
    child: Scaffold(
      body: AbsorbPointer(
        absorbing: busy,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CoreventPageHeader(
                          title: title,
                          description: description,
                          onBack: onBack,
                          backEnabled: !busy,
                        ),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthField extends CoreventField {
  const AuthField({
    super.key,
    required super.label,
    required super.onChanged,
    super.initialValue,
    super.hint,
    super.keyboardType,
    super.password,
    super.digitsOnly,
    super.maxLength,
    super.errorText,
    super.inputFormatters,
    super.autofillHints,
    super.textInputAction,
    super.onSubmitted,
    super.enabled,
  });
}

class AuthPrimaryButton extends CoreventButton {
  const AuthPrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.busy,
  });
}

class AuthTextAction extends CoreventTextAction {
  const AuthTextAction({
    super.key,
    required super.label,
    required super.onPressed,
  });
}

class AuthError extends CoreventNotice {
  const AuthError(String? message, {super.key}) : super(message: message);
}

class AuthSuccess extends CoreventNotice {
  const AuthSuccess(String? message, {super.key})
    : super(message: message, type: CoreventNoticeType.success);
}
