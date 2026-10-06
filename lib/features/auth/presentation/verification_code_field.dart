import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/theme/app_colors.dart';

class VerificationCodeField extends StatefulWidget {
  const VerificationCodeField({
    super.key,
    required this.code,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.onSubmitted,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _focus.addListener(_redraw);
  }

  void _redraw() => setState(() {});

  @override
  void didUpdateWidget(covariant VerificationCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_redraw);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Código de verificação',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 64,
        child: Stack(
          children: [
            Row(
              children: List.generate(
                6,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 6),
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.quick),
                      curve: AppMotion.curve,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border: Border.all(
                          color: widget.errorText != null
                              ? AppColors.error
                              : _focus.hasFocus && index == widget.code.length
                              ? AppColors.primary
                              : AppColors.backgroundSecondary,
                          width: _focus.hasFocus && index == widget.code.length
                              ? 1.5
                              : 1,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          index < widget.code.length ? widget.code[index] : '',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Código de verificação',
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                ),
              ),
            ),
          ],
        ),
      ),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            widget.errorText!,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              color: AppColors.error,
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
    ],
  );
}
