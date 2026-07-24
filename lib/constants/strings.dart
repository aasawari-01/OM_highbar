/// Centralised string constants for the OM Mobile application.
class AppStrings {
  // ── App Info ─────────────────────────────────────────────────
  static const String appName = 'O & M Dashboard';
  static const String appTagline = 'Operations & Maintenance';

  // ── Common UI ────────────────────────────────────────────────
  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String updating = 'Updating...';
  static const String submitting = 'Submitting...';
  static const String adding = 'Adding...';
  static const String deleting = 'Deleting...';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String ok = 'OK';
  static const String retry = 'Retry';
  static const String close = 'Close';

  // ── Snackbar Titles ──────────────────────────────────────────
  static const String success = 'Success';
  static const String error = 'Error';
  static const String validationError = 'Validation Error';
  static const String accessDenied = 'Access Denied';

  // ── Login ────────────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String login = 'Login';
  static const String enterCredentials =
      'Please enter your credentials to access the App';
  static const String emailId = 'Email ID';
  static const String enterEmailId = 'Enter Email ID';
  static const String password = 'Password';
  static const String enterPassword = 'Enter Password';
  static const String rememberMe = 'Remember Me';
  static const String loggingIn = 'Logging in...';
  static const String copyright = '© Copyright Mahametro ';
  static const String allRightsReserved = ', All rights reserved.';
  static const String forgotPassword = 'Forgot Password';


  // ── Drawer / Profile ─────────────────────────────────────────
  static const String editRoleDeptLine = 'Edit Role, Dept. & Line';
  static const String editRoleSubtitle =
      'Please select your Line, Role and Department.';
  static const String selectLine = 'Select Line';
  static const String selectYourLine = 'Select your line';
  static const String selectDepartment = 'Select Department';
  static const String selectDepartmentFirst = 'First Select Department';
  static const String chooseYourDepartment = 'Choose your department';
  static const String selectRole = 'Select Role';
  static const String chooseYourRole = 'Choose your role';
  static const String saveAndContinue = 'Save and Continue';

  // ── Failure Module ────────────────────────────────────────────
  static const String failureCreated = 'Failure created successfully.';
  static const String failureUpdated = 'Failure updated successfully.';
  static const String failureLoadError = 'Failed to load failure details.';
  static const String jiAdded = 'Joint Inspection added successfully.';
  static const String jiUpdated = 'Joint Inspection updated successfully.';
  static const String jiDeleted = 'Joint Inspection deleted successfully.';

  // ── Validation Messages ───────────────────────────────────────
  static const String fieldRequired = 'This field is required.';
  static const String priorityRequired = 'Priority is required.';
  static const String departmentRequired = 'Department is required.';
  static const String locationRequired = 'Location is required.';
  static const String functionalLocationRequired =
      'Functional Location is required.';
  static const String equipmentRequired = 'Equipment No is required.';
  static const String failureOccurrenceRequired =
      'Actual Failure Occurrence is required.';
  static const String failureCategoryRequired =
      'Failure Category Type is required.';
  static const String notificationTypeRequired =
      'Notification Type is required.';
  static const String failureDescriptionRequired =
      'Failure Description is required.';
  static const String failureRectificationRequired =
      'Failure Rectification Details is required.';
  static const String ptwNumberRequired = 'PTW Number is required.';
  static const String rcaRequired = 'Please add at least one RCA detail.';
  static const String userRemarkRequired = "Please enter User's Remark.";
  static const String stationRequired = 'Please select a station.';
  static const String onlyStationControllerCanCreate =
      'Only Station Controller can create station failure.';
  static const String notificationIdUnresolvable =
      'Unable to resolve Notification Id. Please reload and try again.';
}
