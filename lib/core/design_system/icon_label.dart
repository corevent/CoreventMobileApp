import 'package:flutter/material.dart';

/// Aligns the icon with the first line, including wrapped and enlarged text.
class CoreventIconLabel extends StatelessWidget {
  const CoreventIconLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.style,
    required this.iconColor,
    this.iconSize = 17,
    this.spacing = 5,
    this.maxLines,
  });

  final IconData icon;
  final String label;
  final TextStyle style;
  final Color iconColor;
  final double iconSize;
  final double spacing;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(effectiveStyle.fontSize ?? 14) *
        (effectiveStyle.height ?? 1.4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          height: lineHeight,
          child: Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            label,
            style: effectiveStyle.copyWith(
              height: effectiveStyle.height ?? 1.4,
            ),
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
