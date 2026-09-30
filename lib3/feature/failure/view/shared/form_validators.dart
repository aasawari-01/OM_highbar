/// Shared validation functions for form fields
class FormValidators {
  static String? requiredDropdown(String? value, String label) {
    if (value == null || value.trim().isEmpty || value == 'Select' || value == 'Select $label') {
      return '$label is required';
    }
    return null;
  }

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? requiredNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    if (double.tryParse(value) == null) {
      return '$label must be a number';
    }
    return null;
  }

  static String? conditionalRequired(String? value, String label, bool condition) {
    if (condition) {
      return requiredText(value, label);
    }
    return null;
  }
}