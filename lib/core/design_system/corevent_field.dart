import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

class CoreventField extends StatefulWidget {
  const CoreventField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue = '',
    this.hint,
    this.keyboardType,
    this.password = false,
    this.digitsOnly = false,
    this.maxLength,
    this.errorText,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.scrollPadding = const EdgeInsets.all(20),
  });

  final String label;
  final String initialValue;
  final String? hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool password;
  final bool digitsOnly;
  final int? maxLength;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final EdgeInsets scrollPadding;

  @override
  State<CoreventField> createState() => _CoreventFieldState();
}

class _CoreventFieldState extends State<CoreventField> {
  late final TextEditingController _controller;
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _obscured = widget.password;
  }

  @override
  void didUpdateWidget(covariant CoreventField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          scrollPadding: widget.scrollPadding,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          obscureText: _obscured,
          maxLength: widget.maxLength,
          inputFormatters: [
            if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
            ...?widget.inputFormatters,
          ],
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: _obscured ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: widget.enabled
                        ? () => setState(() => _obscured = !_obscured)
                        : null,
                    icon: Icon(
                      _obscured ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                    ),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}
