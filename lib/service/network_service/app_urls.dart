class AppUrls {
  /// Base URL for all API .
  static const String baseUrl = "http://192.168.24.158:5000/api/";
  static const String imageUrl = "http://192.168.24.158:5000/";
  static const String baseUrl8080 = "http://192.168.24.158:8080/api/";

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
  /// OCC failure create. Same endpoints the web "Create OCC Failure" page uses.
  static const String getOccFailureLookups = 'OCCMaintainance/getFailureCreationById';
  /// Reported To (getRoleList), Line and Train Set lists for the OCC forms.
  static const String getOccDeptLocationLookups = 'OCCMaintainance/getFailureCreationDeptLocation';
  /// System / Sub System options for the OCC role (subsystemsForOccs).
  /// Station failure dropdowns: priority, department, location, reported by,
  /// failure category type (all from one call).
  static const String getStationFailureLookups = 'OCCMaintainance/getStationFailureCreationDeptLocation';
  /// Depot failure create form: priority, department, location, reported by,
  /// failure category type (all from one call).
  static const String getDepotFailureLookups = 'OCCMaintainance/getDepotFailureCreationDeptLocation';
  static const String getFailureStandDropDownData = 'FailureStandardized/GetFailureStandDropDownDataNew';
  static const String createOccFailure = 'OCCMaintainance/insertFailureDetails';
  /// Update OCC failure (FMC user) uses the same insert endpoint with an Action.
  static const String updateOccFailure = createOccFailure;
  /// FMC user's OCC failure inbox (same call the web inbox makes).
  static const String getOccFailureInbox = 'OCCMaintainance/getFailureList';
  static const String getStationFailureCreationById = 'OCCMaintainance/getStationFailureCreationById';
  static const String getAllFailuresTransactionData = 'mobileAppAPI/GetAllFailuresTransactionData';
  static const String getStationFailureList = 'OCCMaintainance/getStationFailureList';
  static const String getStationFailureListWithData = 'mobileAppAPI/GetStationFailureListWithData';
  static const String insertChangeDepartmentFailure = 'OCCMaintainance/insertChangeDepartmentFailure';
  static const String updateStationAcknowledgeStatus = 'OCCMaintainance/updateStationAcknowledgeStatus';
  static const String getStationName = 'Lookup/GetLookup_StationName';
  /// Depot failure (DCC role): depot lookup, save selection, failure list.
  static const String getDepotLookup = 'Lookup/GetLookup_Depot';
  static const String insertUserDepotSelection = 'Common/Insert_Users_DepotSelection';
  static const String getDepotFailureList = 'OCCMaintainance/getDepotFailureList';
  static const String updateDepotAcknowledgeStatus = 'OCCMaintainance/updateDepotAcknowledgeStatus';
  static const String getDepotFailureById = 'OCCMaintainance/getDepotFailureCreationById';
  static const String createDepotFailure = 'OCCMaintainance/insertDepotFailureDetails';
  static const String masterDataLogin = 'mobileAppAPI/MasterDataLogin';
  static const String masterDataSync = 'mobileAppAPI/getMasterDataSync';
  static const String rstNotificationInbox = 'CorrectiveNotification/getRSTNotificationInboxJE';
  static const String getRSTFailureData = 'mobileAppAPI/GetRSTFailureData';
  static const String updateRSTNotificationAccept = "JECorrectivesMaintenance/updateRSTNotificationAccept";
  static const String getMCDRequiredQuantity = 'JECorrectivesMaintenance/getMCDRequiredQuantity';
  static const String getMaterialBalancedQty = 'Common/GetMaterialBalancedQty';
  static const String updateNotificationRSTRCAMaterialJE = "JECorrectivesMaintenance/updateNotificationRSTRCAMaterialJE";
  static const String updateRSTNotificationCompletion = 'JECorrectivesMaintenance/updateRSTNotificationCompletion';
  static const String insertUserStationDetails = 'AssetRegister/Insert_Users_Station_Details';
  static const String getAllDataByFuncLocId = 'Common/GetAllDataByFuncLocId';
  static const String occTOscMasterData = 'OccToScCommunication/GetOCCInstructionPageLoadData';
  static const String createOccInstruction = 'OccToScCommunication/CreateOCCInstruction';
  static const String getInstructionList = 'OccToScCommunication/GetInstructionList';
  static const String getInstructionById = 'OccToScCommunication/GetInstructionById';
  static const String acknowledgeSc = 'OccToScCommunication/AcknowledgeInstruction';
  static const String updateAssignUserNotification = 'BreakdownMaintainance/updateAssignUserNotification';
  static const String updateStatusNotificationReject = 'BreakdownMaintainance/updateStatusNotificationReject';
  static const String updateStatusNotificationDelete = 'BreakdownMaintainance/updateStatusNotificationDelete';
  static const String updateAssignUserNotificationCorrection = 'BreakdownMaintainance/updateAssignUserNotificationCorrection';
  static const String getLookupCreateCorrNotification = 'Lookup/GetLookupCreateCorrNotification';
  static const String updateCloseStatusNotification = 'BreakdownMaintainance/updateCloseStatusNotification';
  /// Maintenance form endpoints
  static const String getFunctionalLocationDetails = 'mobileAppAPI/GetFunctionalLocationDetails';
  static const String editNotificationDetails =
      'CorrectiveNotification/editNotificationDetails';
  static const String createNotificationDetails = 'CorrectiveNotification/createNotificationDetails';
  static const String getJEInspectionList = 'Inspection/getJEInspectionList';
  static const String saveCommonInspectionCheckListData = 'Inspection/SaveCommonInspectionCheckListData';
  static const String updateIsSavedCommonInspection = 'Inspection/UpdateIsSavedCommonInspection';
  static const String getCommonInspection = 'Inspection/GetCommonInspection';
  static const String getBMSDetails = 'Inspection/GetBMSDetails';
  static const String insertBMS = 'Inspection/InsertBMS';
  static const String insertBMSFinalSubmit = 'Inspection/InsertBMSFinalSubmit';
  static const String getDGLogDetails = 'Inspection/GetDGLogDetails';
  static const String insertDGLogInspection = 'Inspection/insertDGLogInspection';
  static const String updateDGLogInspection = 'Inspection/UpdateDGLogInspection';
  static const String getLoadDetails = 'Inspection/GetLoadDetails';
  static const String insertLoadDetailsInspection = 'Inspection/insertLoadDetailsInspection';
  static const String getCabPetrollingDetails = 'Inspection/getCabPetrollingDetails';
  static const String getLocationTrainsetDetails = 'Inspection/GetLocationTrainsetDetails';
  static const String insertCabPetrollingInspection = 'Inspection/insertCabPetrollingInspection';
  static const String getCabPetrollingView = 'Inspection/GetCabPetrollingView';
  static const String getBufferStopDetails = 'Inspection/GetBufferStopDetails';
  static const String insertBufferStopInspection = 'Inspection/insertBufferStopInspection';
  static const String getPilotTrainDetail = 'Inspection/GetPilotTrainDetail';
  static const String insertPilotTrainInspection = 'Inspection/insertPilotTrainInspection';
  static const String updatePilotTrainInspection = 'Inspection/UpdatePilotTrainInspection';
  static const String getWeldDetails = 'WeldInspection/GetDetails';
  static const String saveWeldInspection = 'WeldInspection/AddUpdate';
  static const String getCreepMeasurementDetails = 'Inspection/GetCreepMeasurementDetails';
  static const String getCreepMeasurementTimeDetails = 'Inspection/GetCreepMeasrmntTimeDetails';
  static const String insertCreepMeasurementInspection = 'Inspection/insertCreepMeasurementInspection';
  static const String updateCreepMeasurementInspection = 'Inspection/UpdateCreepMeasurementInspection';
  static const String updateIsSavedCreepMeasurement = 'Inspection/UpdateIsSavedCreepMeasurement';
  static const String getFootInspectionDetails = 'Inspection/GetFootInspectionDetails';
  static const String insertFootInspection = 'Inspection/insertFootInspection';
  static const String updateFootInspection = 'Inspection/UpdateFootInspection';
  static const String getOmsActionDetails = 'Inspection/GetOMSActionDetails';
  static const String insertOmsActionInspection = 'Inspection/insertOMSActionInspection';
  static const String updateOmsActionInspection = 'Inspection/UpdateOMSActionInspection';
  static const String getTempMonDetails = 'Inspection/getTempMonDetails';
  static const String getTemperatureUploadData = 'Inspection/GetTemperature_UPLOAD_DATA';
  static const String insertTempMonitoringInspection = 'Inspection/insertTempMonitoringInspection';
  static const String updateIsSaved = 'Inspection/UpdateIsSaved';
  static const String getToeLoadDetails = 'Inspection/GetToeLoadDetails';
  static const String insertToeLoadInspection = 'Inspection/insertToeLoadInspection';
  static const String skipInspectionById = 'Inspection/SkipInspectionById';
}
