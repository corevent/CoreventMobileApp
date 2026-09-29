import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_tokens.dart';

class CoreventButton extends StatefulWidget {
  const CoreventButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  State<CoreventButton> createState() => _CoreventButtonState();
}

class _CoreventButtonState extends State<CoreventButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) {
      if (!widget.busy && widget.onPressed != null) {
        setState(() => _pressed = true);
      }
    },
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: AppMotion.duration(context, AppMotion.quick),
      curve: AppMotion.curve,
      child: ElevatedButton(
        onPressed: widget.busy ? null : widget.onPressed,
        child: widget.busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : Text(widget.label),
      ),
    ),
  );
}

class CoreventTextAction extends StatelessWidget {
  const CoreventTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      overlayColor: Colors.transparent,
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w800,
      ),
    ),
    child: Text(label),
  );
}
