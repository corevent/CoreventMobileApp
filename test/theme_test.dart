import 'package:corevent_mobile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('botão principal não projeta sombra em nenhum estado', () {
    final style = AppTheme.light.elevatedButtonTheme.style!;
    for (final states in <Set<WidgetState>>[
      {},
      {WidgetState.hovered},
      {WidgetState.focused},
      {WidgetState.pressed},
      {WidgetState.disabled},
    ]) {
      expect(style.elevation!.resolve(states), 0);
      expect(style.shadowColor!.resolve(states), Colors.transparent);
    }
  });
}
