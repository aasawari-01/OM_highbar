import 'package:flutter/material.dart';

import 'cust_text.dart';

class YesNoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const YesNoToggle({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? Colors.green : Colors.grey.shade300,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !value ? Colors.white : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustText(
                name: !value ? "No" : "",
                size: 1.6,
                color: value ? Colors.white : Colors.black,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: value ? Colors.white : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustText(
                name: value ? "Yes" : "",
                size: 1.6,
                color: value ? Colors.black : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}