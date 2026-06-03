import 'package:flutter/material.dart';
import 'package:om_mobile/constants/colors.dart';

import 'cust_text.dart';

class AccordionCard extends StatelessWidget {
  final String title;
  final bool? expanded;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget? child;

  const AccordionCard({
    Key? key,
    required this.title,
     this.expanded,
    required this.isExpanded,
    required this.onTap,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          isExpanded
              ? GestureDetector(
                  onTap: onTap,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Row(
                      children: [
                        title==''?SizedBox.shrink():
                        Container(
                          margin: const EdgeInsets.only(left: 15, bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                          child: CustText(
                            name: title,
                            size: 20,
                            color: AppColors.textColor3,
                            fontWeightName: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (expanded != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Icon(
                              (expanded ?? false) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.textColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      title==''?SizedBox.shrink():
                      Container(
                        margin: const EdgeInsets.only(left: 15, bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: CustText(
                          name: title,
                          size: 20,
                          color: AppColors.textColor3,
                          fontWeightName: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
          if (child != null && (expanded ?? false))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}