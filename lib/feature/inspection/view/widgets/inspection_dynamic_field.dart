import 'package:flutter/material.dart';
import '../../../../utils/widgets/cust_date_time_picker.dart';
import '../../../../utils/widgets/cust_dropdown.dart';
import '../../../../utils/widgets/cust_textfield.dart';
import '../../model/checklist_rules.dart';

/// An editable header field of a common inspection (select, time or text).
/// [onChanged] gets the new `fieldSelectedValue`.
class InspectionDynamicField extends StatelessWidget {
  final JsonMap field;
  final bool enabled;

  /// Shows the required marker even when the field itself is not flagged mandatory.
  final bool required;
  final ValueChanged<String> onChanged;

  const InspectionDynamicField({
    super.key,
    required this.field,
    required this.enabled,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final f = field;
    final label = fieldLabel(f) + (required || isMandatoryField(f) ? ' *' : '');
    final current = (f['fieldSelectedValue'] ?? '').toString();

    if (normText(f['fieldType']) == 'select') {
      final options = ((f['selectListItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((o) => MapEntry((o['value'] ?? '').toString(),
              (o['label'] ?? o['value'] ?? '').toString()))
          .toList();
      return CustDropdown(
        label: label,
        hint: 'Select',
        enabled: enabled,
        items: options.map((o) => o.value).toList(),
        selectedValue: options.where((o) => o.key == current).map((o) => o.value).firstOrNull,
        onChanged: (v) {
          final match = options.where((o) => o.value == v);
          onChanged(match.isEmpty || match.first.key == '0' ? '' : match.first.key);
        },
      );
    }
    if (isTimeField(f)) {
      return CustDateTimePicker(
        key: ValueKey('field-${f['fieldID']}'),
        label: label,
        hint: 'Select time',
        pickerType: PickerType.time,
        use24Hour: true,
        enabled: enabled,
        selectedDateTime: parseTimeValue(current),
        onDateTimeSelected: (dt) => onChanged(dt == null ? '' : formatTimeValue(dt)),
      );
    }
    return CustomTextField(
      key: ValueKey('field-${f['fieldID']}'),
      label: label,
      controller: TextEditingController(text: current),
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
