import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/label_value.dart';
import '../../../core/models/functional_location_details.dart';
import '../model/rst_failure_full_response.dart';
import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/local_database_service.dart';
import '../model/failure_detail_response.dart';
import '../model/joint_inspection_history.dart';
import '../model/asset_qr_response.dart';



class FailureService {
  final ApiClient _apiClient = ApiClient();

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthManager().getToken();
    return {
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> saveUserStationDetails(int stationId, String stationName) async {
    try {
      final userId = await AuthManager().getUserId();
      final response = await _apiClient.post(
        AppUrls.insertUserStationDetails,
        body: {
          'CreatedBy': userId,
          'StationId': stationId.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['responseCode'] == 200 || body['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving user station details: $e');
      return false;
    }
  }

  Future<int> _userId() async =>
      int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

  Future<int> getUserId() async =>
      int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

  Future<String> _userName() async =>
      await AuthManager().getUserName() ?? '';

  List<JointInspectionHistory> _mapJIHistory(List<dynamic> raw) =>
      raw.map<JointInspectionHistory>((e) => JointInspectionHistory.fromJson(e as Map<String, dynamic>)).toList();

  // ── JE Failure ────────────────────────────────────────────────────────────

  /// Loads full failure details for the JE change-notification screen.
  Future<FailureDetailResponse> getFailureDetails(String failureNo) async {
    final userId = await _userId();
    final body = {'AssignedUserId': userId, 'Id': failureNo};
    
    debugPrint("========================================");
    debugPrint("JE CHANGE NOTIFICATION API CALL");
    debugPrint("========================================");
    debugPrint("API URL: ${AppUrls.jeChangeNotification}");
    debugPrint("Request Body: $body");
    debugPrint("UserId: $userId");
    debugPrint("FailureNo: $failureNo");
    
    final response = await _apiClient.post(
      AppUrls.jeChangeNotification,
      body: body,
    );
    
    debugPrint("Response Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");
    
    if (response.statusCode != 200) {
      debugPrint("API Error: Server returned status ${response.statusCode}");
      throw Exception('Server error: ${response.statusCode}');
    }
    
    final parsedResponse = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("Parsed Response: $parsedResponse");

    // Check inside responseOutput.getCreateVMModel first
    final responseOutput = parsedResponse['responseOutput'] as Map<String, dynamic>?;
    
    // Log the getCreateVMModel structure
    if (responseOutput != null) {
      final createVMModel = responseOutput['getCreateVMModel'] as Map<String, dynamic>?;
      if (createVMModel != null) {
        debugPrint("=== getCreateVMModel keys ===");
        debugPrint(createVMModel.keys.toString());
        debugPrint("=== getCreateVMModel subsystem field ===");
        debugPrint("subSystems: ${createVMModel['subSystems']}");
        debugPrint("subsystem: ${createVMModel['subsystem']}");
        debugPrint("SubSystems: ${createVMModel['SubSystems']}");
        debugPrint("SubSystem: ${createVMModel['SubSystem']}");
      }
    }
    
    // Extract FailureRectificationJson from the response
    // It can be either a String or a List/Array
    String? failureRectificationJson;
    if (responseOutput != null) {
      final createVMModel = responseOutput['getCreateVMModel'] as Map<String, dynamic>?;
      if (createVMModel != null) {
        final rcaValue = createVMModel['failureRectificationJson'];
        if (rcaValue != null) {
          if (rcaValue is String) {
            failureRectificationJson = rcaValue;
            debugPrint("Service - Found failureRectificationJson inside getCreateVMModel (String): ${failureRectificationJson?.length ?? 0} chars");
          } else if (rcaValue is List) {
            failureRectificationJson = jsonEncode(rcaValue);
            debugPrint("Service - Found failureRectificationJson inside getCreateVMModel (List converted to String): ${failureRectificationJson?.length ?? 0} chars");
          }
        }
      }
    }
    
    // If not found in getCreateVMModel, try top-level as fallback
    if (failureRectificationJson == null) {
      final rcaValue = parsedResponse['FailureRectificationJson'];
      if (rcaValue != null) {
        if (rcaValue is String) {
          failureRectificationJson = rcaValue;
          debugPrint("Service - Found failureRectificationJson at top-level (String): ${failureRectificationJson?.length ?? 0} chars");
        } else if (rcaValue is List) {
          failureRectificationJson = jsonEncode(rcaValue);
          debugPrint("Service - Found failureRectificationJson at top-level (List converted to String): ${failureRectificationJson?.length ?? 0} chars");
        }
      }
    }
    
    debugPrint("Service - Final FailureRectificationJson: ${failureRectificationJson?.length ?? 0} chars");
    
    // Create response with the extracted FailureRectificationJson
    final failureDetailResponse = FailureDetailResponse.fromJson(parsedResponse);
    
    // Override the failureRectificationJson with the extracted value
    final updatedResponse = FailureDetailResponse(
      responseCode: failureDetailResponse.responseCode,
      responseMessage: failureDetailResponse.responseMessage,
      responseOutput: failureDetailResponse.responseOutput,
      failureRectificationJson: failureRectificationJson,
    );
    
    debugPrint("FailureDetailResponse - responseCode: ${updatedResponse.responseCode}");
    debugPrint("FailureDetailResponse - responseMessage: ${updatedResponse.responseMessage}");
    debugPrint("FailureDetailResponse - responseOutput available: ${updatedResponse.responseOutput != null}");
    debugPrint("FailureDetailResponse - failureRectificationJson available: ${updatedResponse.failureRectificationJson != null}");
    
    if (updatedResponse.responseOutput != null) {
      final output = updatedResponse.responseOutput!;
      debugPrint("Response Output Details:");
      debugPrint("  - CreateVMModel: ${output.getCreateVMModel != null}");
      debugPrint("  - DepartmentList: ${output.getDepartmentList?.length ?? 0} items");
      debugPrint("  - UserList: ${output.getUserList?.length ?? 0} items");
      debugPrint("  - ObjectData: ${output.getObjectData?.length ?? 0} items");
      debugPrint("  - MaterialData: ${output.getMaterialData?.length ?? 0} items");
      debugPrint("  - NotificationHistory: ${output.getNotificationHistory?.length ?? 0} items");
      debugPrint("  - JoinInspectionHistory: ${output.getJoinInspectionHistory?.length ?? 0} items");
    }
    
    if (failureDetailResponse.responseOutput != null) {
      final output = failureDetailResponse.responseOutput!;
      debugPrint("Response Output Details:");
      debugPrint("  - CreateVMModel: ${output.getCreateVMModel != null}");
      debugPrint("  - DepartmentList: ${output.getDepartmentList?.length ?? 0} items");
      debugPrint("  - UserList: ${output.getUserList?.length ?? 0} items");
      debugPrint("  - ObjectData: ${output.getObjectData?.length ?? 0} items");
      debugPrint("  - MaterialData: ${output.getMaterialData?.length ?? 0} items");
      debugPrint("  - NotificationHistory: ${output.getNotificationHistory?.length ?? 0} items");
      debugPrint("  - JoinInspectionHistory: ${output.getJoinInspectionHistory?.length ?? 0} items");
    }
    
    debugPrint("========================================");
    
    return updatedResponse;
  }

  /// Submits the JE failure update with optional image files.
  Future<void> updateJEFailure(
    Map<String, dynamic> payload, {
    List<http.MultipartFile> files = const [],
  }) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.updateChangeNotificationJE,
      headers: headers,
      fields: {'ChangeNotifictionJEVM': jsonEncode(payload)},
      files: files,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update failure: ${response.body}');
    }
  }

  /// Returns the fault list for the given object-part ID.
  Future<List<LabelValue>> getFaults(String objectPartId) async {
    final response = await _apiClient.post(
      AppUrls.getFaultMaster,
      body: {'ObjectCodeId': objectPartId, 'FaultCodeId': 0},
    );
    if (response.statusCode != 200) return [];
    final result = FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    if (result.responseCode == 200 && result.responseOutput != null) {
      return result.responseOutput!.getFaultData ?? [];
    }
    return [];
  }

  /// Returns root-cause and action-taken lists for a given object/fault pair.
  Future<({List<LabelValue> rootCauses, List<LabelValue> actionTaken})>
      getRootCauseAndAction(
          String objectCodeId, String faultCodeId) async {
    final response = await _apiClient.post(
      AppUrls.getRootCauseAndActionList,
      body: {'ObjectCodeId': objectCodeId, 'FaultCodeId': faultCodeId},
    );
    final result = FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    if (result.responseCode == 200 && result.responseOutput != null) {
      return (
        rootCauses:
            result.responseOutput!.getRootCausetData ?? <LabelValue>[],
        actionTaken: result.responseOutput!.getActionData ?? <LabelValue>[],
      );
    }
    throw Exception(result.responseMessage ?? 'Failed to load RCA data');
  }

  // ── Station Failure ───────────────────────────────────────────────────────



  /// Creates a new station failure. Returns the created failure number.
  Future<String?> createStationFailure(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    debugPrint("createStationFailure: API endpoint: ${AppUrls.createStationFailure}");
    debugPrint("createStationFailure: Request headers: $headers");
    debugPrint("createStationFailure: Request payload: $payload");
    final response = await _apiClient.postMultipart(
      AppUrls.createStationFailure,
      headers: headers,
      fields: {'StationFailureCreationDetails': jsonEncode(payload)},
    );
    debugPrint("createStationFailure: Response status: ${response.statusCode}");
    debugPrint("createStationFailure: Response body: ${response.body}");
    if (response.statusCode != 200) {
      throw Exception('Failed to create station failure: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("createStationFailure: Parsed response: $body");
    if (body['responseCode'] != 200) {
      throw Exception(
          body['responseMessage'] ?? 'Failed to create station failure');
    }
    return body['responseOutput']?.toString();
  }

  /// Updates an existing station failure.
  Future<void> updateStationFailure(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.insertChangeDepartmentFailure,
      headers: headers,
      fields: {'StationFailureCreationDetails': jsonEncode(payload)},
    );
    debugPrint("response---${jsonDecode(response.body)}");
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200) {
      throw Exception(body['responseMessage'] ?? 'Failed to update');
    }
  }

  /// Returns station names for the station picker popup.
  Future<List<LabelValue>> getStationNames() async {
    // First try to load from local database
    try {
      final dbService = LocalDatabaseService();
      final localStations = await dbService.getStations();
      if (localStations.isNotEmpty) {
        debugPrint("getStationNames: Loaded ${localStations.length} stations from local DB");
        return localStations.map((e) => LabelValue(
          label: e['stationLabel']?.toString() ?? '',
          value: e['stationValue']?.toString() ?? '',
        )).toList();
      }
    } catch (e) {
      debugPrint("getStationNames: Error loading from local DB: $e");
    }

    // Fallback to API if local data is not available
    debugPrint("getStationNames: No local data, fetching from API");
    final userId = await AuthManager().getUserId() ?? '1';
    final response = await _apiClient
        .get('${AppUrls.getStationName}?AssgineUserId=$userId');
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] == 200 && body['responseOutput'] != null) {
      final stations = (body['responseOutput'] as List)
          .map((e) => LabelValue(
                label: e['label']?.toString() ?? '',
                value: e['value']?.toString() ?? '',
              ))
          .toList();
      
      // Save stations to local database for offline access
      try {
        final dbService = LocalDatabaseService();
        final stationMaps = stations.map((s) => {
          'label': s.label,
          'value': s.value,
        }).toList();
        await dbService.insertStations(stationMaps);
        debugPrint("getStationNames: Saved ${stations.length} stations to local DB");
      } catch (e) {
        debugPrint("getStationNames: Error saving to local DB: $e");
      }
      
      return stations;
    }
    return [];
  }

  /// Returns station failure details for a given failure ID.
  Future<Map<String, dynamic>> getStationFailureDetails(String id) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.insertChangeDepartmentFailure,
      body: {
        'Id': id,
        'UserId': userId,
        'Action': 'GetStationFailureDetails'
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(body['responseMessage'] ?? 'Failed to load station failure details');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Fetches station failure list from API with data
  /// If lastSyncDate is null, fetches all data. If provided, fetches only data after that date.
  Future<List<Map<String, dynamic>>> getStationFailureListWithData({String? lastSyncDate}) async {
    final userId = await _userId();
    debugPrint("getStationFailureListWithData: Calling API with UserId=$userId, lastSyncDate=$lastSyncDate");
    debugPrint("getStationFailureListWithData: API endpoint: ${AppUrls.getStationFailureListWithData}");
    
    final body = <String, dynamic>{'UserId': userId};
    if (lastSyncDate != null) {
      body['lastSyncDate'] = lastSyncDate;
    }
    
    try {
      debugPrint("getStationFailureListWithData: About to call _apiClient.post() with 10 second timeout");
      final response = await _apiClient.post(
        AppUrls.getStationFailureListWithData,
        body: body,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("getStationFailureListWithData: TIMEOUT after 10 seconds");
        throw Exception('Request timed out after 10 seconds');
      });
      debugPrint("getStationFailureListWithData: API call completed");
      
      debugPrint("getStationFailureListWithData: Response status: ${response.statusCode}");
      debugPrint("getStationFailureListWithData: Response body: ${response.body}");
      
      if (response.statusCode != 200) {
        debugPrint("getStationFailureListWithData: API call failed with status ${response.statusCode}");
        throw Exception('Server error: ${response.statusCode}');
      }
      
      final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("getStationFailureListWithData: Parsed response: success=${bodyJson['success']}, message=${bodyJson['message']}");
      
      // Handle the actual response structure: {success: true, message: "...", data: {stationFailureList: []}}
      if (bodyJson['success'] == true && bodyJson['data'] != null) {
        final data = bodyJson['data'] as Map<String, dynamic>;
        final failureList = data['stationFailureList'];
        debugPrint("getStationFailureListWithData: stationFailureList type: ${failureList.runtimeType}");
        
        if (failureList is List) {
          debugPrint("getStationFailureListWithData: Returning list with ${failureList.length} items");
          return failureList.cast<Map<String, dynamic>>();
        }
      }
      
      debugPrint("getStationFailureListWithData: No valid data found in response");
      return [];
    } catch (e) {
      debugPrint("getStationFailureListWithData: Exception occurred: $e");
      debugPrint("getStationFailureListWithData: Exception type: ${e.runtimeType}");
      rethrow;
    }
  }

  // ── Joint Inspection ──────────────────────────────────────────────────────

  /// Returns the joint inspection history for a notification.
  Future<List<JointInspectionHistory>> getJIHistory(int notifId) async {
    final headers = await _authHeaders();
    final userName = await _userName();
    final body = {
      'Type': 'GetJoinInspectionHistory',
      'NotificationId': notifId,
      'CreatedByName': userName,
    };
    final response = await _apiClient.postMultipart(
      AppUrls.addUpdateDeleteJointInspection,
      headers: headers,
      fields: {'JoinInspectionHistory': jsonEncode(body)},
    );
    if (response.statusCode != 200) return [];
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody['responseCode'] == 200) {
      return _mapJIHistory(jsonBody['responseOutput'] as List? ?? []);
    }
    return [];
  }

  /// Adds a new joint inspection entry. Returns updated history list.
  Future<List<JointInspectionHistory>> addJIEntry(
      Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.addUpdateDeleteJointInspection,
      headers: headers,
      fields: {'JoinInspectionHistory': jsonEncode(body)},
    );
    if (response.statusCode != 200) throw Exception('Failed to add.');
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody['responseCode'] == 200) {
      return _mapJIHistory(jsonBody['responseOutput'] as List? ?? []);
    }
    throw Exception(jsonBody['responseMessage'] ?? 'Failed to add.');
  }

  /// Updates an existing joint inspection entry. Returns updated list.
  Future<List<JointInspectionHistory>> updateJIEntry(
      Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.addUpdateDeleteJointInspection,
      headers: headers,
      fields: {'JoinInspectionHistory': jsonEncode(body)},
    );
    if (response.statusCode != 200) throw Exception('Failed to update.');
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody['responseCode'] == 200) {
      return _mapJIHistory(jsonBody['responseOutput'] as List? ?? []);
    }
    throw Exception(jsonBody['responseMessage'] ?? 'Failed to update.');
  }

  /// Deletes a joint inspection entry. Returns updated list (null if none).
  Future<List<JointInspectionHistory>?> deleteJIEntry(
      int jiId, int notifId) async {
    final headers = await _authHeaders();
    final userName = await _userName();
    final body = {
      'JIId': jiId,
      'Type': 'DeleteJointInspection',
      'NotificationId': notifId,
      'CreatedByName': userName,
    };
    final response = await _apiClient.postMultipart(
      AppUrls.addUpdateDeleteJointInspection,
      headers: headers,
      fields: {'JoinInspectionHistory': jsonEncode(body)},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete.');
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody['responseCode'] == 200) {
      final output = jsonBody['responseOutput'] as List?;
      return output != null ? _mapJIHistory(output) : null;
    }
    throw Exception(jsonBody['responseMessage'] ?? 'Failed to delete.');
  }

  /// Loads JI screen details for the JE joint-inspection view.
  Future<FailureDetailResponse> getJIScreenDetails(String failureNo) async {
    final userId = await _userId();
    final response = await _apiClient.get(
      '${AppUrls.getJointInspectionJEScreenDetails}'
      '?notificationID=$failureNo&userId=$userId',
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Submits joint-inspection JE screen data. Returns the response message.
  Future<String> submitJIScreenData(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.saveJointInspectionScreenDetails,
      headers: headers,
      fields: {'SaveJointInspectionScreenData': jsonEncode(payload)},
    );
    if (response.statusCode != 200) {
      throw Exception('Submission failed. Status: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] == 200) {
      return body['responseMessage'] ??
          'Joint Inspection Details Updated Successfully';
    }
    throw Exception(body['responseMessage'] ?? 'Submission failed');
  }

  /// Returns the user list for joint inspection dept selection.
  Future<List<LabelValue>> getJIUsers(String deptId) async {
    final createdBy = await _userId();
    final response = await _apiClient.get(
      '${AppUrls.getFunctionLocEquipmentNoByDeptIdJI}'
      '?deptId=$deptId&createdBy=$createdBy',
    );
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = FailureDetailResponse.fromJson(body);
    if (result.responseCode != 200 || result.responseOutput == null) return [];
    final outputJson = body['responseOutput'] as Map<String, dynamic>?;
    if (outputJson == null) return [];
    final userListJson = (outputJson['getAssgineUserList'] ??
        outputJson['getUserList'] ??
        outputJson['userList'] ??
        outputJson['getUsers'] ??
        outputJson['getUserData']) as List?;
    if (userListJson == null) return [];
    return userListJson
        .map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
        .where((u) =>
            u.value != '0' &&
            u.label?.trim().toLowerCase() != 'select user')
        .toList();
  }

  /// Returns the master department list for joint inspection
  // Future<List<LabelValue>> getDeptMasterData() async {
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetDeptMasterData'},
  //   );
  //   debugPrint("getDeptMasterData statusCode: ${response.statusCode}");
  //   if (response.statusCode != 200) return [];
  //
  //   final body = jsonDecode(response.body) as Map<String, dynamic>;
  //   debugPrint("getDeptMasterData response keys: ${body.keys.toList()}");
  //   debugPrint("getDeptMasterData full response: $body");
  //
  //   // Try different response structures
  //   if (body['responseCode'] == 200 && body['responseOutput'] != null) {
  //     final departments = body['responseOutput'] as List?;
  //     if (departments != null) {
  //       debugPrint("getDeptMasterData found departments in responseOutput: ${departments.length} items");
  //       return departments
  //           .map((e) => LabelValue(
  //                 label: e['deptName']?.toString() ?? e['label']?.toString() ?? '',
  //                 value: e['deptId']?.toString() ?? e['value']?.toString() ?? '',
  //               ))
  //           .toList();
  //     }
  //   }
  //
  //   if (body['success'] == true && body['data'] != null) {
  //     final departments = body['data']['departments'] as List?;
  //     if (departments != null) {
  //       debugPrint("getDeptMasterData found departments in data.departments: ${departments.length} items");
  //       return departments
  //           .map((e) => LabelValue(
  //                 label: e['deptName']?.toString() ?? '',
  //                 value: e['deptId']?.toString() ?? '',
  //               ))
  //           .toList();
  //     }
  //   }
  //
  //   debugPrint("getDeptMasterData: No departments found in response");
  //   return [];
  // }

  // ── RST List ──────────────────────────────────────────────────────────────

  /// Returns the RST notification inbox list for JE
  Future<Map<String, dynamic>> getRstList() async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.rstNotificationInbox,
      body: {
        "Id": "0",
        "UserId": userId,
        "Action": "getRSTNotificationInboxJE"
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(body['responseMessage'] ?? 'Failed to load RST list');
    }
    return body;
  }

  /// Returns the full RST failure response (rstFetchData + related lists)
  Future<RstFailureFullResponse> getRstFailureFullData(int notificationId) async {
    final response = await _apiClient.post(
      '${AppUrls.getRSTFailureData}?NotificationId=$notificationId',
      body: {},
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("body===$body");
    debugPrint("documnents====${body['data']['documents']}");
    if (body['success'] != true || body['data'] == null) {
      throw Exception(body['message'] ?? 'Failed to load RST failure data');
    }
    return RstFailureFullResponse.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Returns MCD required quantity for RST material selection
  Future<Map<String, dynamic>> getMCDRequiredQuantity(int objectCodeId, int faultCodeId) async {
    final response = await _apiClient.post(
      AppUrls.getMCDRequiredQuantity,
      body: {'ObjectCodeId': objectCodeId, 'FaultCodeId': faultCodeId},
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(body['responseMessage'] ?? 'Failed to load MCD required quantity');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Returns material balanced quantity for RST store location selection
  Future<Map<String, dynamic>> getMaterialBalancedQty(int materialId, int storageLocationId, int userId) async {
    final response = await _apiClient.post(
      AppUrls.getMaterialBalancedQty,
      body: {
        'MaterialId': materialId,
        'StorageLocationId': storageLocationId,
        'CommonText': 'GetByMaterialAndStorageId',
        'UserId': userId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(body['responseMessage'] ?? 'Failed to load material balanced quantity');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  // ── RST Master Data ─────────────────────────────────────────────────────────

  // /// Fetches and stores RST failure types locally
  // Future<void> fetchRstFailureTypes() async {
  //   final dbService = LocalDatabaseService();
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetRSTFailureTypeData'},
  //   );
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as Map<String, dynamic>;
  //     if (body['success'] == true && body['data'] != null) {
  //       final failureTypes = (body['data']['failureTypes'] as List?)
  //               ?.map((e) => RstFailureType.fromJson(e as Map<String, dynamic>))
  //               .toList() ??
  //           [];
  //       await dbService.insertRstFailureTypes(failureTypes);
  //     }
  //   }
  // }
  //
  // /// Fetches and stores RST object parts locally
  // Future<void> fetchRstObjectParts() async {
  //   final dbService = LocalDatabaseService();
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetObjectPartForRST'},
  //   );
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as Map<String, dynamic>;
  //     if (body['success'] == true && body['data'] != null) {
  //       final objectParts = (body['data']['objectParts'] as List?)
  //               ?.map((e) => RstObjectPart.fromJson(e as Map<String, dynamic>))
  //               .toList() ??
  //           [];
  //       await dbService.insertRstObjectParts(objectParts);
  //     }
  //   }
  // }
  //
  // /// Fetches and stores RST materials locally
  // Future<void> fetchRstMaterials() async {
  //   final dbService = LocalDatabaseService();
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetMaterialMasterData'},
  //   );
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as Map<String, dynamic>;
  //     if (body['success'] == true && body['data'] != null) {
  //       final materials = (body['data']['materials'] as List?)
  //               ?.map((e) => RstMaterial.fromJson(e as Map<String, dynamic>))
  //               .toList() ??
  //           [];
  //       await dbService.insertRstMaterials(materials);
  //     }
  //   }
  // }
  //
  // /// Fetches and stores RST storage locations locally
  // Future<void> fetchRstStorageLocations() async {
  //   final dbService = LocalDatabaseService();
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetStorageLocationData'},
  //   );
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as Map<String, dynamic>;
  //     if (body['success'] == true && body['data'] != null) {
  //       final storageLocations = (body['data']['storageLocations'] as List?)
  //           ?.map((e) => LabelValue(
  //         label: e['storageLocation']?.toString() ?? '',   // ✅ correct source field
  //         value: e['storageRowId']?.toString() ?? '',       // ✅ correct source field
  //       ))
  //           .toList() ??
  //           [];
  //       await dbService.insertRstStorageLocations(storageLocations);
  //     }
  //   }
  // }
  // /// Fetches and stores RST train statuses locally
  // Future<void> fetchRstTrainStatuses() async {
  //   final dbService = LocalDatabaseService();
  //   final response = await _apiClient.post(
  //     AppUrls.getMasterData,
  //     body: {'action': 'GetRSTTrainStatusData'},
  //   );
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as Map<String, dynamic>;
  //     if (body['success'] == true && body['data'] != null) {
  //       final trainStatuses = (body['data']['trainStatuses'] as List?)
  //               ?.map((e) => RstTrainStatus.fromJson(e as Map<String, dynamic>))
  //               .toList() ??
  //           [];
  //       await dbService.insertRstTrainStatuses(trainStatuses);
  //     }
  //   }
  // }

  Future<String> updateRstNotificationAccept({
    required int notificationId,
    required List<Map<String, dynamic>> dataWorkAlloted,
    required bool isWorkAllotedAccept,
    required bool isPowerBlockReq,
  }) async {
    final userId = await _userId();
    final headers = await _authHeaders();

    final payload = {
      "Id": notificationId,
      "DataWorkAlloted": dataWorkAlloted,
      "IsWorkAllotedAccept": isWorkAllotedAccept,
      "UserId": userId,
      "IsPowerBlockReq": isPowerBlockReq,
    };
    final response = await _apiClient.postMultipart(
      AppUrls.updateRSTNotificationAccept,
      headers: headers,
      fields: {'RSTUpdateNotificationAccept': jsonEncode(payload)},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("body---$body");
    if (body['responseCode'] == 200 || body['success'] == true) {
      return (body['responseMessage'] ?? body['message'] ?? 'Submitted successfully').toString();
    }
    throw Exception(body['responseMessage'] ?? body['message'] ?? 'Submission failed');
  }
  /// Submits Part D (RCA + material required/dismantle/swapped) for an RST notification.
  Future<String> updateNotificationRSTRCAMaterialJE(
      Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.updateNotificationRSTRCAMaterialJE,
      headers: headers,
      fields: {'ChangeRSTNotifictionJEVM': jsonEncode(payload)},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("updateNotificationRSTRCAMaterialJE response---$body");
    if (body['responseCode'] == 200 || body['success'] == true) {
      return (body['responseMessage'] ?? body['message'] ?? 'Submitted successfully').toString();
    }
    throw Exception(body['responseMessage'] ?? body['message'] ?? 'Submission failed');
  }

  String _formatDdMmYyyyHm(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  /// Submits Part E (work completion) for an RST notification.
  Future<String> updateRstNotificationCompletion({
    required int notificationId,
    required String trainStatusId,
    required DateTime actualWorkStart,
    required DateTime actualWorkComplete,
    List<http.MultipartFile> afterImages = const [],
    List<http.MultipartFile> rcaImages = const [],
  }) async {
    final userId = await _userId();
    final headers = await _authHeaders();

    final payload = {
      "Id": notificationId,
      "IsWorkCompletion": true,
      "TrainStatusId": trainStatusId,
      "ActualWorkStartDate": _formatDdMmYyyyHm(actualWorkStart),
      "ActualWorkCompleteDate": _formatDdMmYyyyHm(actualWorkComplete),
      "UserId": userId,
      "CreatedBy": userId,
    };

    final response = await _apiClient.postMultipart(
      AppUrls.updateRSTNotificationCompletion,
      headers: headers,
      fields: {'RSTWorkCompletionDetails': jsonEncode(payload)},
      files: [...afterImages, ...rcaImages],
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("updateRstNotificationCompletion response---$body");
    if (body['responseCode'] == 200 || body['success'] == true) {
      return (body['responseMessage'] ?? body['message'] ?? 'Submitted successfully').toString();
    }
    throw Exception(body['responseMessage'] ?? body['message'] ?? 'Submission failed');
  }

  /// Fetches all RST master data
  // Future<void> fetchRstMasterData() async {
  //   await Future.wait([
  //     fetchRstFailureTypes(),
  //     fetchRstObjectParts(),
  //     fetchRstMaterials(),
  //     fetchRstTrainStatuses(),
  //     fetchRstStorageLocations(),
  //   ]);
  // }

  /// Fetches asset data by functional location ID for QR scan
  Future<AssetQrResponse> getAssetDataByFuncLocId(String funcLocId) async {
    final userId = await _userId();
    debugPrint("getAssetDataByFuncLocId: Calling API with funcLocId=$funcLocId, userId=$userId");
    
    final response = await _apiClient.post(
      AppUrls.getAllDataByFuncLocId,
      body: {
        "CreatedBy": userId,
        "FuncLocId": funcLocId,
        "IsSearchFilter": 0
      },
    );
    
    debugPrint("getAssetDataByFuncLocId: Response status: ${response.statusCode}");
    debugPrint("getAssetDataByFuncLocId: Response body: ${response.body}");
    
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AssetQrResponse.fromJson(body);
  }

  // ── Section Incharge API Methods ─────────────────────────────────────────────

  /// Assign user to notification
  Future<bool> assignUserNotification({
    required int notificationId,
    required int assignedUserId,
    required String description,
  }) async {
    final userId = await _userId();
    final userName = await _userName();

    final body = {
      'jobCardNo': notificationId.toString(),
      'AssignedUserId': assignedUserId,
      'CreatedBy': userId,
      'CreatedByName': userName,
      'Description': description,
    };

    debugPrint("assignUserNotification: Request body: $body");

    final response = await _apiClient.post(
      AppUrls.updateAssignUserNotification,
      body: body,
    );

    debugPrint("assignUserNotification: Response status: ${response.statusCode}");
    debugPrint("assignUserNotification: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 && responseBody['responseOutput'] == true;
  }

  /// Reject notification for duplicate
  Future<bool> rejectNotification({
    required int notificationId,
    required String description,
  }) async {
    final userId = await _userId();
    final userName = await _userName();

    final body = {
      'jobCardNo': notificationId.toString(),
      'CreatedBy': userId,
      'CreatedByName': userName,
      'Description': description,
    };

    debugPrint("rejectNotification: Request body: $body");

    final response = await _apiClient.post(
      AppUrls.updateStatusNotificationReject,
      body: body,
    );

    debugPrint("rejectNotification: Response status: ${response.statusCode}");
    debugPrint("rejectNotification: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 && responseBody['responseOutput'] == true;
  }

  // ── Maintenance Form API Methods ─────────────────────────────────────────────

  /// Returns person responsible list for a given department
  Future<({List<LabelValue>? users, String? errorMessage})> getPersonResponsible(int departmentId) async {
    try {
      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: {'action': 'GetUserListByDept', 'deptId': departmentId},
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['responseCode'] == 200 && body['responseOutput'] != null) {
        final users = (body['responseOutput'] as List?)
            ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
            .toList();
        return (users: users, errorMessage: null);
      }
      return (users: null, errorMessage: body['responseMessage']?.toString());
    } catch (e) {
      return (users: null, errorMessage: e.toString());
    }
  }

  /// Returns functional location details including system, equipment, history, measurement points
  Future<({FunctionalLocationDetails? details, String? errorMessage})> getFunctionalLocationDetails(
    String functionalLocation,
  ) async {
    try {
      final response = await _apiClient.post(
        AppUrls.getFunctionalLocationDetails,
        body: {'functionalLocation': functionalLocation},
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['responseCode'] == 200 && body['responseOutput'] != null) {
        final details = FunctionalLocationDetails.fromJson(
          body['responseOutput'] as Map<String, dynamic>
        );
        return (details: details, errorMessage: null);
      }
      return (details: null, errorMessage: body['responseMessage']?.toString());
    } catch (e) {
      return (details: null, errorMessage: e.toString());
    }
  }

  /// Returns subsystems filtered by selected system
  Future<({List<LabelValue>? subsystems, String? errorMessage})> getSubsystems(String system) async {
    try {
      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: {'action': 'GetSubSystemData', 'system': system},
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['responseCode'] == 200 && body['responseOutput'] != null) {
        final subsystems = (body['responseOutput'] as List?)
            ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
            .toList();
        return (subsystems: subsystems, errorMessage: null);
      }
      return (subsystems: null, errorMessage: body['responseMessage']?.toString());
    } catch (e) {
      return (subsystems: null, errorMessage: e.toString());
    }
  }

  /// Returns nature of work and failure type data for department ID 3
  Future<({List<LabelValue>? natureOfWorkList, List<LabelValue>? failureTypeList, String? errorMessage})> getNatureOfWorkData(int departmentId) async {
    try {
      final response = await _apiClient.post(
        AppUrls.getMasterData,
        body: {'action': 'GetNatureOfWorkData', 'deptId': departmentId},
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['responseCode'] == 200 && body['responseOutput'] != null) {
        final output = body['responseOutput'] as Map<String, dynamic>;
        final natureOfWorkList = (output['natureOfWorkList'] as List?)
            ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
            .toList();
        final failureTypeList = (output['failureTypeList'] as List?)
            ?.map((e) => LabelValue.fromJson(e as Map<String, dynamic>))
            .toList();
        return (natureOfWorkList: natureOfWorkList, failureTypeList: failureTypeList, errorMessage: null);
      }
      return (natureOfWorkList: null, failureTypeList: null, errorMessage: body['responseMessage']?.toString());
    } catch (e) {
      return (natureOfWorkList: null, failureTypeList: null, errorMessage: e.toString());
    }
  }

  /// Submits maintenance form with optional attachments
  Future<({bool success, String? errorMessage})> submitMaintenanceForm(
    Map<String, dynamic> formData,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await _apiClient.postMultipart(
        AppUrls.submitMaintenanceForm,
        headers: headers,
        fields: {'MaintenanceFormData': jsonEncode(formData)},
      );
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['responseCode'] == 200 || body['success'] == true) {
        return (success: true, errorMessage: null);
      }
      return (success: false, errorMessage: body['responseMessage']?.toString() ?? body['message']?.toString());
    } catch (e) {
      return (success: false, errorMessage: e.toString());
    }
  }

  /// Delete notification
  Future<bool> deleteNotification({
    required int notificationId,
    required String description,
  }) async {
    final userId = await _userId();
    final userName = await _userName();

    final body = {
      'jobCardNo': notificationId.toString(),
      'CreatedBy': userId,
      'CreatedByName': userName,
      'Description': description,
    };

    debugPrint("deleteNotification: Request body: $body");

    final response = await _apiClient.post(
      AppUrls.updateStatusNotificationDelete,
      body: body,
    );

    debugPrint("deleteNotification: Response status: ${response.statusCode}");
    debugPrint("deleteNotification: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 && responseBody['responseOutput'] == true;
  }

  /// Send for correction with user assignment
  Future<bool> sendForCorrection({
    required int notificationId,
    required int assignedUserId,
    required String description,
  }) async {
    final userId = await _userId();
    final userName = await _userName();

    final body = {
      'jobCardNo': notificationId.toString(),
      'AssignedUserId': assignedUserId,
      'CreatedBy': userId,
      'CreatedByName': userName,
      'Description': description,
    };

    debugPrint("sendForCorrection: Request body: $body");

    final response = await _apiClient.post(
      AppUrls.updateAssignUserNotificationCorrection,
      body: body,
    );

    debugPrint("sendForCorrection: Response status: ${response.statusCode}");
    debugPrint("sendForCorrection: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 && responseBody['responseOutput'] == true;
  }
}
