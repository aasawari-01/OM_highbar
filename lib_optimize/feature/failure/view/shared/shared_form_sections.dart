import 'package:flutter/material.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/utils/widgets/cust_section.dart';
import 'package:om_mobile/utils/widgets/cust_textfield.dart';
import 'package:om_mobile/utils/widgets/cust_dropdown.dart';
import 'package:om_mobile/utils/widgets/cust_toggle.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';
import 'package:om_mobile/utils/widgets/cust_button.dart';
import 'package:om_mobile/utils/widgets/cust_outline_button.dart';

/// Shared form section builders to reduce code duplication
class SharedFormSections {
  /// Builds a basic information section with common fields
  static Widget buildBasicInfoSection({
    required List<Widget> children,
    VoidCallback? onExpandCollapse,
    bool isExpanded = true,
    String title = "Basic Information",
  }) {
    return CustSection(
      title: title,
      trailing: onExpandCollapse != null
          ? _buildExpandCollapseButton(isExpanded, onExpandCollapse)
          : null,
      isVisible: isExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Builds a service affected section with toggle and conditional fields
  static Widget buildServiceAffectedSection({
    required bool isServiceAffected,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
    bool enabled = true,
  }) {
    return CustSection(
      title: "Service Affected",
      trailing: YesNoToggle(
        value: isServiceAffected,
        onChanged: enabled ? onToggle : (value) {},
      ),
      isVisible: isServiceAffected,
      child: Column(
        children: children,
      ),
    );
  }

  /// Builds a passenger deboarding section with toggle and conditional fields
  static Widget buildPassengerDeboardingSection({
    required bool isPassengerDeboarding,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
    bool enabled = true,
  }) {
    return CustSection(
      title: "Passenger Deboarding",
      trailing: YesNoToggle(
        value: isPassengerDeboarding,
        onChanged: enabled ? onToggle : (value) {},
      ),
      isVisible: isPassengerDeboarding,
      child: Column(
        children: children,
      ),
    );
  }

  /// Builds a passenger affected section with toggle and conditional fields
  static Widget buildPassengerAffectedSection({
    required bool isPassengerAffected,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
    bool enabled = true,
  }) {
    return CustSection(
      title: "Passenger Affected",
      trailing: YesNoToggle(
        value: isPassengerAffected,
        onChanged: enabled ? onToggle : (value) {},
      ),
      isVisible: isPassengerAffected,
      child: Column(
        children: children,
      ),
    );
  }

  /// Builds a row of two text fields
  static Widget buildTextFieldRow({
    required TextEditingController controller1,
    required String label1,
    required TextEditingController controller2,
    required String label2,
    String? hint1,
    String? hint2,
    bool enabled1 = true,
    bool enabled2 = true,
    String? Function(String?)? validator1,
    String? Function(String?)? validator2,
    TextInputType? keyboardType1,
    TextInputType? keyboardType2,
  }) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            label: label1,
            controller: controller1,
            hintText: hint1,
            enabled: enabled1,
            validator: validator1,
            keyboardType: keyboardType1 ?? TextInputType.text,
          ),
        ),
        const SizedBox(width: AppConstants.elementSpacing),
        Expanded(
          child: CustomTextField(
            label: label2,
            controller: controller2,
            hintText: hint2,
            enabled: enabled2,
            validator: validator2,
            keyboardType: keyboardType2 ?? TextInputType.text,
          ),
        ),
      ],
    );
  }

  /// Builds a row of two dropdowns
  static Widget buildDropdownRow({
    required List<String> items1,
    required String? selectedValue1,
    required ValueChanged<String?> onChanged1,
    required String label1,
    required List<String> items2,
    required String? selectedValue2,
    required ValueChanged<String?> onChanged2,
    required String label2,
    String? hint1,
    String? hint2,
    bool enabled1 = true,
    bool enabled2 = true,
    String? Function(String?)? validator1,
    String? Function(String?)? validator2,
  }) {
    return Row(
      children: [
        Expanded(
          child: CustDropdown(
            label: label1,
            hint: hint1 ?? 'Select...',
            items: items1,
            selectedValue: selectedValue1,
            onChanged: onChanged1,
            enabled: enabled1,
            validator: validator1,
          ),
        ),
        const SizedBox(width: AppConstants.elementSpacing),
        Expanded(
          child: CustDropdown(
            label: label2,
            hint: hint2 ?? 'Select...',
            items: items2,
            selectedValue: selectedValue2,
            onChanged: onChanged2,
            enabled: enabled2,
            validator: validator2,
          ),
        ),
      ],
    );
  }

  /// Builds a functional location dropdown with loading state
  static Widget buildFunctionalLocationDropdown({
    required bool isLoading,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Loading functional locations...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return CustDropdown(
      label: "Functional Location *",
      hint: "Select...",
      items: items,
      selectedValue: selectedValue,
      onChanged: onChanged,
      enabled: enabled,
      validator: validator,
    );
  }

  /// Builds an equipment dropdown with loading state
  static Widget buildEquipmentDropdown({
    required bool isLoading,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return CustDropdown(
      label: "Equipment Number",
      hint: isLoading ? "Loading..." : "Select equipment",
      items: items,
      selectedValue: selectedValue,
      onChanged: enabled && !isLoading ? onChanged : (value) {},
      enabled: enabled && !isLoading,
      validator: validator,
    );
  }

  static Widget _buildExpandCollapseButton(bool isExpanded, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        isExpanded ? Icons.remove : Icons.add,
        color: AppColors.orangeColor,
        size: 30,
      ),
      onPressed: onPressed,
    );
  }

  /// Builds an attachments section for station controller forms
  static Widget buildAttachmentsSection({
    required bool isFormDisabled,
    required List<Map<String, String>> beforeFiles,
    required VoidCallback onUploadBefore,
  }) {
    return CustSection(
      title: "Attachments",
      child: Column(
        children: [
          Row(
            children: [
              CustText.body("Before ", fontWeightName: FontWeight.w500),
              const Text("(Max File Size 1MB)",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: AppConstants.sectionSpacing),
              _buildUploadButton(onUploadBefore, enabled: true),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: beforeFiles
                .map<Widget>((file) => _buildAttachmentItem(
                    file['name']!,
                    file['size']!,
                    beforeFiles,
                    file))
                .toList(),
          ),
        ],
      ),
    );
  }

  static Widget _buildUploadButton(VoidCallback onPressed, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.orangeColor : Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text("Upload", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  static Widget _buildAttachmentItem(
    String name,
    String size,
    List<Map<String, String>> filesList,
    Map<String, String> file,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, color: AppColors.orangeColor, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(size, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              filesList.remove(file);
            },
            child: const Icon(Icons.close, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }
}