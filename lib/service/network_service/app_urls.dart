class AppUrls {
  /// Base URL for all API .
   static const String baseUrl = "http://192.168.24.158:5000/api/";
   static const String imageUrl = "http://192.168.24.158:5000/";

   /// Auth endpoints
  static const String login = 'UserLogin/userLoginValidate';
  static const String logout = 'UserLogin/userLogout';

  /// Failure endpoints
  static const String jeInboxList = 'JECorrectivesMaintenance/jeinboxlist';
  static const String jeJointInboxList = 'JECorrectivesMaintenance/jejointinboxlist';
  static const String jeChangeNotification = 'JECorrectivesMaintenance/jeChangeNotification';
  static const String getJointInspectionJEScreenDetails = 'JECorrectivesMaintenance/GetJointInspectionJEScreenDetails';
  static const String saveJointInspectionScreenDetails = 'JECorrectivesMaintenance/SaveJointInspectionScreenDetails';
  static const String getFaultMaster = 'JECorrectivesMaintenance/getFaultMaster';
  static const String getFunctionEqDetailsById = 'JECorrectivesMaintenance/getFunctionEqDetailsById';
  static const String updateChangeNotificationJE = 'JECorrectivesMaintenance/updateChangeNotificationJE';
  static const String getRootCauseAndActionList = 'JECorrectivesMaintenance/getRootCauseAndActionList';
  static const String getFunctionLocEquipmentNoByDeptIdJI = 'JECorrectivesMaintenance/getFunctionLocEquipmentNoByDeptIdJI';
  static const String getFunctionLocEquipmentNoByDeptId = 'JECorrectivesMaintenance/getFunctionLocEquipmentNoByDeptId';
  static const String addUpdateDeleteJointInspection = 'JECorrectivesMaintenance/addUpdateDeleteJointInspection';
  static const String createStationFailure = 'OCCMaintainance/insertStationFailureDetails';
  static const String getStationFailureList = 'OCCMaintainance/getStationFailureList';
  static const String getStationFailureClosedList = 'OCCMaintainance/getStationFailureClosedList';
  static const String getStationFailureCreationById = 'OCCMaintainance/getStationFailureCreationById';
  static const String insertChangeDepartmentFailure = 'OCCMaintainance/insertChangeDepartmentFailure';
  static const String updateStationAcknowledgeStatus = 'OCCMaintainance/updateStationAcknowledgeStatus';
  static const String getStationName = 'Lookup/GetLookup_StationName';
  static const String getMasterData = 'mobileAppAPI/GetMasterData';
  static const String rstNotificationInbox = 'CorrectiveNotification/getRSTNotificationInboxJE';
  static const String getRSTFailureData = 'mobileAppAPI/GetRSTFailureData';
  static const String updateRSTNotificationAccept = "JECorrectivesMaintenance/updateRSTNotificationAccept";
  static const String getMCDRequiredQuantity = 'JECorrectivesMaintenance/getMCDRequiredQuantity';
  static const String getMaterialBalancedQty = 'Common/GetMaterialBalancedQty';
  static const String updateNotificationRSTRCAMaterialJE = "JECorrectivesMaintenance/updateNotificationRSTRCAMaterialJE";
  static const String updateRSTNotificationCompletion = 'JECorrectivesMaintenance/updateRSTNotificationCompletion';

}
