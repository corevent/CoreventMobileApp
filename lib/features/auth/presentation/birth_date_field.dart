import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/theme/app_colors.dart';

/// Direct entry is faster than navigating decades in a month calendar.
class BirthDateField extends StatefulWidget {
  const BirthDateField({
    super.key,
    required this.initialDate,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime?> onChanged;
  final String? errorText;

  @override
  State<BirthDateField> createState() => _BirthDateFieldState();
}

class _BirthDateFieldState extends State<BirthDateField> {
  late final TextEditingController _day;
  late final TextEditingController _month;
  late final TextEditingController _year;
  final _dayFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate;
    _day = TextEditingController(
      text: date == null ? '' : '${date.day}'.padLeft(2, '0'),
    );
    _month = TextEditingController(
      text: date == null ? '' : '${date.month}'.padLeft(2, '0'),
    );
    _year = TextEditingController(text: date == null ? '' : '${date.year}');
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  void _update() {
    final day = int.tryParse(_day.text);
    final month = int.tryParse(_month.text);
    final year = int.tryParse(_year.text);
    if (_day.text.length != 2 ||
        _month.text.length != 2 ||
        _year.text.length != 4 ||
        day == null ||
        month == null ||
        year == null) {
      setState(() => _inputError = null);
      widget.onChanged(null);
      return;
    }
    if (year < 1900) {
      setState(() => _inputError = 'Informe um ano a partir de 1900.');
      widget.onChanged(null);
      return;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      setState(() => _inputError = 'Esta data não existe.');
      widget.onChanged(null);
      return;
    }
    if (date.isAfter(DateTime.now())) {
      setState(() => _inputError = 'A data não pode estar no futuro.');
      widget.onChanged(null);
      return;
    }
    setState(() => _inputError = null);
    widget.onChanged(date);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Data de nascimento',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: _part(
              'Dia',
              'DD',
              _day,
              2,
              _dayFocus,
              () => _monthFocus.requestFocus(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _part(
              'Mês',
              'MM',
              _month,
              2,
              _monthFocus,
              () => _yearFocus.requestFocus(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _part(
              'Ano',
              'AAAA',
              _year,
              4,
              _yearFocus,
              () => _yearFocus.unfocus(),
            ),
          ),
        ],
      ),
      if (widget.errorText != null || _inputError != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            widget.errorText ?? _inputError!,
            style: const TextStyle(
              color: AppColors.error,
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
            ),
          ),
        ),
    ],
  );

  Widget _part(
    String label,
    String hint,
    TextEditingController controller,
    int length,
    FocusNode? focusNode,
    VoidCallback next,
  ) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.number,
    textInputAction: label == 'Ano'
        ? TextInputAction.done
        : TextInputAction.next,
    textAlign: TextAlign.center,
    maxLength: label == 'Dia' ? null : length,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    autofillHints: label == 'Ano' ? const [AutofillHints.birthdayYear] : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: AppColors.surface,
      errorText: null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: BorderSide(
          color: widget.errorText == null && _inputError == null
              ? AppColors.backgroundSecondary
              : AppColors.error,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    onChanged: (value) {
      if (label == 'Dia' && value.length == 8) {
        _day.text = value.substring(0, 2);
        _month.text = value.substring(2, 4);
        _year.text = value.substring(4, 8);
        _yearFocus.unfocus();
        _update();
        return;
      }
      if (label == 'Dia' && value.length > 2) {
        _day.value = TextEditingValue(
          text: value.substring(0, 2),
          selection: const TextSelection.collapsed(offset: 2),
        );
      }
      _update();
      if (value.length == length) next();
      if (value.isEmpty && label == 'Mês') _dayFocus.requestFocus();
      if (value.isEmpty && label == 'Ano') _monthFocus.requestFocus();
    },
    onSubmitted: (_) => next(),
  );
}
