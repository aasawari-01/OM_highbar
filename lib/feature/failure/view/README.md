# Failure Feature - View Structure

## Overview
This directory contains the view layer for the failure feature, reorganized to reduce code duplication and improve maintainability.

## Directory Structure

```
view/
├── forms/                          # Form-specific screens
│   ├── create_failure_screen.dart  # Main failure creation screen
│   └── create_maintenance_form.dart # Maintenance form screen
├── shared/                         # Shared components and utilities
│   ├── form_field_config.dart      # Form field configuration definitions
│   ├── form_field_widgets.dart     # Reusable form field widgets
│   ├── form_validators.dart        # Shared validation functions
│   ├── shared_form_sections.dart   # Reusable form section builders
│   └── unified_form_builder.dart   # Unified form building logic
├── failure_list_screen.dart       # Failure list screen
├── maintenance_history_screen.dart # Maintenance history screen
├── view_detail_screen.dart         # Detail view screen
└── rst/                            # RST-specific screens
    ├── rst_failure_screen.dart
    ├── rst_list_screen.dart
    └── sic_checklist_screen.dart
```

## Key Improvements

### 1. Eliminated Code Duplication
- **Removed** separate part files (`create_failure_screen_je.dart`, `create_failure_screen_station.dart`)
- **Consolidated** validation logic into `form_validators.dart`
- **Unified** form section builders in `shared_form_sections.dart`

### 2. Shared Components
- **Form Validators**: Centralized validation functions (required, conditional, etc.)
- **Form Sections**: Reusable section builders for common patterns (service affected, passenger affected, etc.)
- **Form Field Widgets**: Configurable widgets with role-based permissions
- **Form Field Config**: Declarative field configuration with role-based visibility/editability

### 3. Improved Organization
- **forms/**: Contains actual form screens
- **shared/**: Contains reusable components and utilities
- **rst/**: Contains RST-specific functionality

## Usage Examples

### Using Shared Validators
```dart
import 'shared/form_validators.dart';

// Instead of defining validation functions locally
validator: (val) => FormValidators.requiredDropdown(val, 'Priority')
```

### Using Shared Form Sections
```dart
import 'shared/shared_form_sections.dart';

// Instead of building custom sections
SharedFormSections.buildServiceAffectedSection(
  isServiceAffected: controller.isServiceAffected.value,
  onToggle: (val) => controller.isServiceAffected.value = val,
  children: [/* field widgets */],
)
```

### Using Form Field Configuration
```dart
import 'shared/form_field_config.dart';
import 'shared/form_field_widgets.dart';

final config = FormFieldConfigs.priority;
FormFieldWidgets.buildDropdown(
  config: config,
  items: items,
  selectedValue: selectedValue,
  onChanged: onChanged,
  currentUserRole: UserRole.juniorEngineer,
)
```

## Migration Notes

### Removed Files
- `create_failure_screen_je.dart` (merged into main screen)
- `create_failure_screen_station.dart` (merged into main screen)

### Updated Imports
If you were importing from the old locations, update your imports:
```dart
// Old
import 'package:om_mobile/feature/failure/view/create_failure_screen.dart';

// New
import 'package:om_mobile/feature/failure/view/forms/create_failure_screen.dart';
```

## Benefits

1. **Reduced Code Duplication**: Shared validation and UI components
2. **Easier Maintenance**: Changes to validation logic only need to be made once
3. **Better Testing**: Shared components can be tested independently
4. **Role-Based Access**: Built-in support for role-based field visibility/editability
5. **Consistent UI**: Shared components ensure consistent styling and behavior
6. **Scalability**: Easy to add new form types using the shared components

## Future Improvements

- Consider extracting the RST screens into a separate feature module
- Add comprehensive unit tests for shared components
- Create form configuration files for different form types
- Implement form state management using the unified builder
- Add form field validation at the configuration level