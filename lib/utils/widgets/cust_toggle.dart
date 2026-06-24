import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';

import 'cust_text.dart';

class YesNoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const YesNoToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFE5E5E5).withOpacity(enabled ? 1.0 : 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: enabled ? () => onChanged(false) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: !value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !value ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
              ),
              child: CustText(
                name: "No",
                size: 14,
                color: !value ? (enabled ? Colors.black87 : Colors.grey) : Colors.grey.shade600,
                fontWeightName: !value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: enabled ? () => onChanged(true) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: value && enabled ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: value ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
              ),
              child: CustText(
                name: "Yes",
                size: 14,
                color: value && enabled ? Colors.white : Colors.grey.shade600,
                fontWeightName: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
