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

  Future<String> _userName() async => await AuthManager().getUserName() ?? '';

  List<JointInspectionHistory> _mapJIHistory(List<dynamic> raw) => raw
      .map<JointInspectionHistory>(
          (e) => JointInspectionHistory.fromJson(e as Map<String, dynamic>))
      .toList();

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
    final responseOutput =
    parsedResponse['responseOutput'] as Map<String, dynamic>?;

    // Log the getCreateVMModel structure
    if (responseOutput != null) {
      final createVMModel =
      responseOutput['getCreateVMModel'] as Map<String, dynamic>?;
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
      final createVMModel =
      responseOutput['getCreateVMModel'] as Map<String, dynamic>?;
      if (createVMModel != null) {
        final rcaValue = createVMModel['failureRectificationJson'];
        if (rcaValue != null) {
          if (rcaValue is String) {
            failureRectificationJson = rcaValue;
            debugPrint(
                "Service - Found failureRectificationJson inside getCreateVMModel (String): ${failureRectificationJson?.length ?? 0} chars");
          } else if (rcaValue is List) {
            failureRectificationJson = jsonEncode(rcaValue);
            debugPrint(
                "Service - Found failureRectificationJson inside getCreateVMModel (List converted to String): ${failureRectificationJson?.length ?? 0} chars");
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
          debugPrint(
              "Service - Found failureRectificationJson at top-level (String): ${failureRectificationJson?.length ?? 0} chars");
        } else if (rcaValue is List) {
          failureRectificationJson = jsonEncode(rcaValue);
          debugPrint(
              "Service - Found failureRectificationJson at top-level (List converted to String): ${failureRectificationJson?.length ?? 0} chars");
        }
      }
    }

    debugPrint(
        "Service - Final FailureRectificationJson: ${failureRectificationJson?.length ?? 0} chars");

    // Create response with the extracted FailureRectificationJson
    final failureDetailResponse =
    FailureDetailResponse.fromJson(parsedResponse);

    // Override the failureRectificationJson with the extracted value
    final updatedResponse = FailureDetailResponse(
      responseCode: failureDetailResponse.responseCode,
      responseMessage: failureDetailResponse.responseMessage,
      responseOutput: failureDetailResponse.responseOutput,
      failureRectificationJson: failureRectificationJson,
    );

    debugPrint(
        "FailureDetailResponse - responseCode: ${updatedResponse.responseCode}");
    debugPrint(
        "FailureDetailResponse - responseMessage: ${updatedResponse.responseMessage}");
    debugPrint(
        "FailureDetailResponse - responseOutput available: ${updatedResponse.responseOutput != null}");
    debugPrint(
        "FailureDetailResponse - failureRectificationJson available: ${updatedResponse.failureRectificationJson != null}");

    if (updatedResponse.responseOutput != null) {
      final output = updatedResponse.responseOutput!;
      debugPrint("Response Output Details:");
      debugPrint("  - CreateVMModel: ${output.getCreateVMModel != null}");
      debugPrint(
          "  - DepartmentList: ${output.getDepartmentList?.length ?? 0} items");
      debugPrint("  - UserList: ${output.getUserList?.length ?? 0} items");
      debugPrint("  - ObjectData: ${output.getObjectData?.length ?? 0} items");
      debugPrint(
          "  - MaterialData: ${output.getMaterialData?.length ?? 0} items");
      debugPrint(
          "  - NotificationHistory: ${output.getNotificationHistory?.length ?? 0} items");
      debugPrint(
          "  - JoinInspectionHistory: ${output.getJoinInspectionHistory?.length ?? 0} items");
    }

    if (failureDetailResponse.responseOutput != null) {
      final output = failureDetailResponse.responseOutput!;
      debugPrint("Response Output Details:");
      debugPrint("  - CreateVMModel: ${output.getCreateVMModel != null}");
      debugPrint(
          "  - DepartmentList: ${output.getDepartmentList?.length ?? 0} items");
      debugPrint("  - UserList: ${output.getUserList?.length ?? 0} items");
      debugPrint("  - ObjectData: ${output.getObjectData?.length ?? 0} items");
      debugPrint(
          "  - MaterialData: ${output.getMaterialData?.length ?? 0} items");
      debugPrint(
          "  - NotificationHistory: ${output.getNotificationHistory?.length ?? 0} items");
      debugPrint(
          "  - JoinInspectionHistory: ${output.getJoinInspectionHistory?.length ?? 0} items");
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
  getRootCauseAndAction(String objectCodeId, String faultCodeId) async {
    final response = await _apiClient.post(
      AppUrls.getRootCauseAndActionList,
      body: {'ObjectCodeId': objectCodeId, 'FaultCodeId': faultCodeId},
    );
    final result = FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    if (result.responseCode == 200 && result.responseOutput != null) {
      return (
      rootCauses: result.responseOutput!.getRootCausetData ?? <LabelValue>[],
      actionTaken: result.responseOutput!.getActionData ?? <LabelValue>[],
      );
    }
    throw Exception(result.responseMessage ?? 'Failed to load RCA data');
  }

  // ── Station Failure ───────────────────────────────────────────────────────

  /// Gets functional location details for maintenance form
  Future<FunctionalLocationDetailsResponse> getFunctionalLocationDetails(
      String functionLocationId) async {
    print("functionLocationId==+$functionLocationId");
    final response = await _apiClient.post(
      AppUrls.getFunctionEqDetailsById,
      body: {'FunctionLocationId': functionLocationId},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load functional location details: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return FunctionalLocationDetailsResponse.fromJson(responseBody);
  }

  /// Gets subsystems for a given system (reusing existing JE API)
  Future<SubsystemsResponse> getSubsystems(String system) async {
    final response = await _apiClient.post(
      AppUrls.jeChangeNotification,
      body: {'System': system},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load subsystems: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return SubsystemsResponse.fromJson(responseBody);
  }

  /// Gets person responsible users for a department (reusing existing API)
  Future<PersonResponsibleResponse> getPersonResponsible(
      int departmentId) async {
    final response = await _apiClient.post(
      AppUrls.getFunctionLocEquipmentNoByDeptId,
      body: {'DeptId': departmentId},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load person responsible: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return PersonResponsibleResponse.fromJson(responseBody);
  }

  /// Gets users by department ID (reusing existing API)
  Future<PersonResponsibleResponse> getUsersByDepartmentId(
      int departmentId, String userId) async {
    final response = await _apiClient.post(
      AppUrls.getFunctionLocEquipmentNoByDeptId,
      body: {'DeptId': departmentId, 'UserId': userId},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return PersonResponsibleResponse.fromJson(responseBody);
  }

  /// Gets nature of work data for department ID 3 (placeholder for now)
  Future<NatureOfWorkResponse> getNatureOfWorkData(int departmentId) async {
    // For now, return a mock response since the specific API may not exist
    return NatureOfWorkResponse(
      natureOfWorkList: [
        LabelValue(label: 'Routine Maintenance', value: '1'),
        LabelValue(label: 'Breakdown Maintenance', value: '2'),
        LabelValue(label: 'Preventive Maintenance', value: '3'),
      ],
      failureTypeList: [
        LabelValue(label: 'Major', value: '1'),
        LabelValue(label: 'Minor', value: '2'),
        LabelValue(label: 'Critical', value: '3'),
      ],
    );
  }

  /// Gets lookup data for creating a new notification
  /// Returns getNatureOfWorkList and getNotificationTypeList for dropdowns
  Future<FailureDetailResponse> getLookupCreateCorrNotification() async {
    final userId = await _userId();
    debugPrint(
        "getLookupCreateCorrNotification: Starting API call with userId=$userId");

    try {
      final response = await _apiClient
          .get(
        '${AppUrls.getLookupCreateCorrNotification}?AssgineUserId=$userId',
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint(
              "getLookupCreateCorrNotification: Request timed out after 60 seconds");
          throw Exception('Request timed out after 60 seconds');
        },
      );

      debugPrint(
          "getLookupCreateCorrNotification: Response status: ${response.statusCode}");
      debugPrint(
          "getLookupCreateCorrNotification: Response body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to load lookup data: ${response.statusCode}');
      }

      return FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint("getLookupCreateCorrNotification: Error occurred: $e");
      rethrow;
    }
  }

  /// Creates a new station failure. Returns the created failure number.
  Future<String?> createStationFailure(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    debugPrint(
        "createStationFailure: API endpoint: ${AppUrls.createStationFailure}");
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

  /// Reported To (getRoleList), Line (getLineList) and Train Set
  /// (getTrainSetList) for the OCC create / update forms.
  Future<Map<String, dynamic>> getOccDeptLocationLookups() async {
    final userId = await _userId();
    final headers = await _authHeaders();
    final response = await _apiClient.post(
      AppUrls.getOccDeptLocationLookups,
      headers: headers,
      body: {
        'LocationId': 0,
        'UserId': userId,
        'DepartmentIds': '',
        'Action': 'Get_Failure_Dept_Location_User',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(body['responseMessage'] ?? 'Failed to load OCC lookups');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// System -> Sub System options for the OCC role. Returns the
  /// `subsystemsForOccs` rows: [{system: "...", subSystem: ["...", ...]}].
  Future<List<Map<String, dynamic>>> getOccSystemSubsystems(
      {String departmentIds = ''}) async {
    final userId = await _userId();
    final headers = await _authHeaders();
    final response = await _apiClient.post(
      AppUrls.getFailureStandDropDownData,
      headers: headers,
      body: {
        'userId': userId,
        'system': '',
        'locationTypeId': 0,
        'funcLocId': 0,
        'action': 'GetSystemSubSystemForOcc',
        'failureCategoryId': 0,
        'causeOfFailureId': 0,
        'departmentIds': departmentIds,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    final rows = data is Map ? data['subsystemsForOccs'] : null;
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// FMC user's OCC failure inbox. Returns the raw rows; the response may be a
  /// plain list or an object that holds the list, so both are handled.
  ///
  /// [action] defaults to the FMC inbox ('FailureInboxList'); the OCC role's
  /// own list uses 'FailureList'.
  Future<List<Map<String, dynamic>>> getOccFailureInbox(
      {String action = 'FailureInboxList'}) async {
    final userId = await _userId();
    final headers = await _authHeaders();
    final response = await _apiClient.post(
      AppUrls.getOccFailureInbox,
      headers: headers,
      body: {
        'action': action,
        'userId': userId,
        'startDate': null,
        'endDate': null,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200) {
      throw Exception(body['responseMessage'] ?? 'Failed to load failures');
    }
    final out = body['responseOutput'];
    Iterable? rows;
    if (out is List) {
      rows = out;
    } else if (out is Map) {
      for (final k in const [
        'failureInboxList', 'failureList', 'inboxList', 'getFailureList', 'list'
      ]) {
        if (out[k] is List) {
          rows = out[k] as List;
          break;
        }
      }
      if (rows == null) {
        final lists = out.values.whereType<List>().toList();
        if (lists.isNotEmpty) rows = lists.first;
      }
    }
    return (rows ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Loads one OCC failure (plus its lookups, history and images) for the FMC
  /// update screen. `id` is the failure's id string from the list.
  Future<Map<String, dynamic>> getOccFailureById(String id) async {
    final userId = await _userId();
    final headers = await _authHeaders();
    final response = await _apiClient.post(
      AppUrls.getOccFailureLookups,
      headers: headers,
      body: {
        'Id': id,
        'UserId': userId,
        'DepartmentIds': '',
        'Action': '',
        'LocationId': 0,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(
          body['responseMessage'] ?? 'Failed to load OCC failure details');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Creates an OCC failure. Mirrors the web page: the JSON goes in the
  /// `FailureCreationDetails` field and "before" images in `beforImage`
  /// (spelling is the server's). Returns the generated failure number.
  Future<String?> createOccFailure(
    Map<String, dynamic> payload, {
    List<http.MultipartFile> files = const [],
  }) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.createOccFailure,
      headers: headers,
      fields: {'FailureCreationDetails': jsonEncode(payload)},
      files: files,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create OCC failure: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseMessage'] != 'Success' && body['responseCode'] != 200) {
      throw Exception(
          body['responseMessage']?.toString() ?? 'Failed to create OCC failure');
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
        debugPrint(
            "getStationNames: Loaded ${localStations.length} stations from local DB");
        return localStations
            .map((e) => LabelValue(
          label: e['stationLabel']?.toString() ?? '',
          value: e['stationValue']?.toString() ?? '',
        ))
            .toList();
      }
    } catch (e) {
      debugPrint("getStationNames: Error loading from local DB: $e");
    }

    // Fallback to API if local data is not available
    debugPrint("getStationNames: No local data, fetching from API");
    final userId = await AuthManager().getUserId() ?? '1';
    final response =
    await _apiClient.get('${AppUrls.getStationName}?AssgineUserId=$userId');
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
        final stationMaps = stations
            .map((s) => {
          'label': s.label,
          'value': s.value,
        })
            .toList();
        await dbService.insertStations(stationMaps);
        debugPrint(
            "getStationNames: Saved ${stations.length} stations to local DB");
      } catch (e) {
        debugPrint("getStationNames: Error saving to local DB: $e");
      }

      return stations;
    }
    return [];
  }

  // ── Depot Failure (DCC) ───────────────────────────────────────────────────

  /// Returns depots for the depot picker popup.
  Future<List<LabelValue>> getDepotNames() async {
    final userId = await _userId();
    final response =
    await _apiClient.get('${AppUrls.getDepotLookup}?UserId=$userId');
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] == 200 && body['responseOutput'] is List) {
      return (body['responseOutput'] as List)
          .whereType<Map>()
          .map((e) => LabelValue(
        label: e['label']?.toString() ?? '',
        value: e['value']?.toString() ?? '',
      ))
          .toList();
    }
    return [];
  }

  /// Saves the depot the DCC user picked.
  Future<bool> saveUserDepot(int depotId) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.insertUserDepotSelection,
      body: {'CreatedBy': userId, 'DepotId': depotId},
    );
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['responseCode'] == 200 || body['success'] == true;
  }

  /// Depot Re-open / Close (same endpoint the web depot list uses).
  /// [action] is UPDATE_REOPEN_OCC_DEPOT or UPDATE_CLOSED_OCC_DEPOT.
  Future<Map<String, dynamic>> updateDepotStatus({
    required int id,
    required String action,
    required String description,
    required int statusId,
  }) async {
    final userId = await _userId();
    final userName = await _userName();
    final response = await _apiClient.post(
      AppUrls.updateDepotAcknowledgeStatus,
      body: {
        'Action': action,
        'Id': id,
        'CreatedBy': userId,
        'Description': description,
        'CreatedByName': userName,
        'StatusId': statusId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Loads one depot failure (details, history, images). `id` is the
  /// encrypted failure id from the depot list.
  Future<Map<String, dynamic>> getDepotFailureById(String id) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.getDepotFailureById,
      body: {
        'Id': id,
        'UserId': userId,
        'DepartmentIds': '',
        'Action': '',
        'LocationId': 0,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(
          body['responseMessage'] ?? 'Failed to load depot failure details');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Creates a depot failure. The JSON goes in `DepotFailureCreationDetails`
  /// and "before" images in `beforImage` (spelling is the server's).
  Future<String?> createDepotFailure(
      Map<String, dynamic> payload, {
        List<http.MultipartFile> files = const [],
      }) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.createDepotFailure,
      headers: headers,
      fields: {'DepotFailureCreationDetails': jsonEncode(payload)},
      files: files,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create depot failure: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseMessage'] != 'Success' && body['responseCode'] != 200) {
      throw Exception(
          body['responseMessage']?.toString() ?? 'Failed to create depot failure');
    }
    return body['responseOutput']?.toString();
  }

  /// Depot failure list for the selected depot. Returns the raw rows; the
  /// response may be a plain list or an object holding the list.
  Future<List<Map<String, dynamic>>> getDepotFailureList(int depotId) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.getDepotFailureList,
      body: {
        'locationId': 0,
        'depotId': depotId,
        'userId': userId,
        'departmentIds': '',
        'action': '',
        'id': '',
        'startDate': null,
        'endDate': null,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200) {
      throw Exception(body['responseMessage'] ?? 'Failed to load depot failures');
    }
    final out = body['responseOutput'];
    Iterable? rows;
    if (out is List) {
      rows = out;
    } else if (out is Map) {
      for (final k in const [
        'depotFailureList', 'failureList', 'failureInboxList', 'list'
      ]) {
        if (out[k] is List) {
          rows = out[k] as List;
          break;
        }
      }
      if (rows == null) {
        final lists = out.values.whereType<List>().toList();
        if (lists.isNotEmpty) rows = lists.first;
      }
    }
    return (rows ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Returns station failure details for a given failure ID.
  Future<Map<String, dynamic>> getStationFailureDetails(String id) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.insertChangeDepartmentFailure,
      body: {'Id': id, 'UserId': userId, 'Action': 'GetStationFailureDetails'},
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(
          body['responseMessage'] ?? 'Failed to load station failure details');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Fetches station failure list from API with data
  /// If lastSyncDate is null, fetches all data. If provided, fetches only data after that date.
  Future<List<Map<String, dynamic>>> getStationFailureListWithData(
      {String? lastSyncDate}) async {
    final userId = await _userId();
    debugPrint(
        "getStationFailureListWithData: Calling API with UserId=$userId, lastSyncDate=$lastSyncDate");
    debugPrint(
        "getStationFailureListWithData: API endpoint: ${AppUrls.getStationFailureListWithData}");

    final body = <String, dynamic>{'UserId': userId};
    // if (lastSyncDate != null) {
    //   body['lastSyncDate'] = lastSyncDate;
    // }

    try {
      debugPrint(
          "getStationFailureListWithData: About to call _apiClient.post() with 10 second timeout");
      final response = await _apiClient
          .post(
        AppUrls.getStationFailureListWithData,
        body: body,
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("getStationFailureListWithData: TIMEOUT after 10 seconds");
        throw Exception('Request timed out after 10 seconds');
      });
      debugPrint("getStationFailureListWithData: API call completed");

      debugPrint(
          "getStationFailureListWithData: Response status: ${response.statusCode}");
      debugPrint(
          "getStationFailureListWithData: Response body: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint(
            "getStationFailureListWithData: API call failed with status ${response.statusCode}");
        throw Exception('Server error: ${response.statusCode}');
      }

      final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint(
          "getStationFailureListWithData: Parsed response: success=${bodyJson['success']}, message=${bodyJson['message']}");

      // Handle the actual response structure: {success: true, message: "...", data: {stationFailureList: []}}
      if (bodyJson['success'] == true && bodyJson['data'] != null) {
        final data = bodyJson['data'] as Map<String, dynamic>;
        final failureList = data['stationFailureList'];
        debugPrint(
            "getStationFailureListWithData: stationFailureList type: ${failureList.runtimeType}");

        if (failureList is List) {
          debugPrint(
              "getStationFailureListWithData: Returning list with ${failureList.length} items");
          return failureList.cast<Map<String, dynamic>>();
        }
      }

      debugPrint(
          "getStationFailureListWithData: No valid data found in response");
      return [];
    } catch (e) {
      debugPrint("getStationFailureListWithData: Exception occurred: $e");
      debugPrint(
          "getStationFailureListWithData: Exception type: ${e.runtimeType}");
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
  /// Raw JSON version so jeScreenDetails is not lost.
  Future<Map<String, dynamic>> getJIScreenDetailsRaw(String failureNo) async {
    final userId = await _userId();
    final response = await _apiClient.get(
      '${AppUrls.getJointInspectionJEScreenDetails}'
          '?notificationID=$failureNo&userId=$userId',
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
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
    u.value != '0' && u.label?.trim().toLowerCase() != 'select user')
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
  Future<RstFailureFullResponse> getRstFailureFullData(
      int notificationId) async {
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
    return RstFailureFullResponse.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  /// Returns MCD required quantity for RST material selection
  Future<Map<String, dynamic>> getMCDRequiredQuantity(
      int objectCodeId, int faultCodeId) async {
    final response = await _apiClient.post(
      AppUrls.getMCDRequiredQuantity,
      body: {'ObjectCodeId': objectCodeId, 'FaultCodeId': faultCodeId},
    );
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200 || body['responseOutput'] == null) {
      throw Exception(
          body['responseMessage'] ?? 'Failed to load MCD required quantity');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Returns material balanced quantity for RST store location selection
  Future<Map<String, dynamic>> getMaterialBalancedQty(
      int materialId, int storageLocationId, int userId) async {
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
      throw Exception(body['responseMessage'] ??
          'Failed to load material balanced quantity');
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
      return (body['responseMessage'] ??
          body['message'] ??
          'Submitted successfully')
          .toString();
    }
    throw Exception(
        body['responseMessage'] ?? body['message'] ?? 'Submission failed');
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
      return (body['responseMessage'] ??
          body['message'] ??
          'Submitted successfully')
          .toString();
    }
    throw Exception(
        body['responseMessage'] ?? body['message'] ?? 'Submission failed');
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
      return (body['responseMessage'] ??
          body['message'] ??
          'Submitted successfully')
          .toString();
    }
    throw Exception(
        body['responseMessage'] ?? body['message'] ?? 'Submission failed');
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
    debugPrint(
        "getAssetDataByFuncLocId: Calling API with funcLocId=$funcLocId, userId=$userId");

    final response = await _apiClient.post(
      AppUrls.getAllDataByFuncLocId,
      body: {"CreatedBy": userId, "FuncLocId": funcLocId, "IsSearchFilter": 0},
    );

    debugPrint(
        "getAssetDataByFuncLocId: Response status: ${response.statusCode}");
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
    required String notificationId,
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

    debugPrint(
        "assignUserNotification: Response status: ${response.statusCode}");
    debugPrint("assignUserNotification: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 &&
        responseBody['responseOutput'] == true;
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
    return responseBody['responseCode'] == 200 &&
        responseBody['responseOutput'] == true;
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
    return responseBody['responseCode'] == 200 &&
        responseBody['responseOutput'] == true;
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
    return responseBody['responseCode'] == 200 &&
        responseBody['responseOutput'] == true;
  }

  // ── Maintenance Form Submission (Section Incharge) ────────────────────────────────────────

  /// Submits maintenance failure notification for Section Incharge
  Future<Map<String, dynamic>> submitMaintenanceNotificationForm(
      Map<String, dynamic> formData) async {
    final userId = await _userId();
    final userName = await _userName();

    debugPrint("========================================");
    debugPrint("MAINTENANCE FORM SUBMISSION API CALL");
    debugPrint("========================================");
    debugPrint("API URL: ${AppUrls.createNotificationDetails}");
    debugPrint("Request Body: $formData");
    debugPrint("UserId: $userId, UserName: $userName");

    final requestBody = {
      'Description': formData['failureDescription'] ?? '',
      'NatureOfWorkId': formData['natureOfWorkId'] ?? 0,
      'TrainRunningKM': formData['trainRunningKM'],
      'NotificationTypeId': formData['notificationTypeId'] ?? 0,
      'FunctionLocationId': formData['functionLocationId'] ?? 0,
      'EquipmentId': formData['equipmentId'] ?? 0,
      'ActualFailureOccuranceOn':
      formData['actualFailureOccuranceOn'] ?? '',
      'AssignedUserId': formData['assignedUserId'] ?? userId,
      'IsServiceAffected': formData['isServiceAffected'] ?? false,
      'TrainDelayInMin': formData['trainDelayInMin'] ?? 0,
      'TrainDelayInNo': formData['trainDelayInNo'] ?? 0,
      'NoOfTranWithdrawal': formData['noOfTranWithdrawal'] ?? 0,
      'NoOfTranCancel': formData['noOfTranCancel'] ?? 0,
      'NoOfTrainReplace': formData['noOfTrainReplace'] ?? 0,
      'IsPassengerDeboarding':
      formData['isPassengerDeboarding'] ?? false,
      'NoofTrainDeboarded':
      formData['noofTrainDeboarded'] ?? 0,
      'IsOHEReq': formData['isOHEReq'] ?? false,
      'IsSICReq': formData['isSICReq'] ?? false,
      'IsJointInspectionReq':
      formData['isJointInspectionReq'] ?? false,
      'AssignedUserId_JI':
      formData['assignedUserId_JI'],
      'DeptId_JI':
      formData['deptId_JI'],
      'DeptId': formData['deptId'] ?? 0,
      'Remark_JE': formData['remarkJE'] ?? 0,
      'CreatedBy': userId,
      'IsPassengerAffected':
      formData['isPassengerAffected'] ?? false,
      'NoOfPassengerAffected':
      formData['noOfPassengerAffected'],
      'TrappedDuration':
      formData['trappedDuration'],
      'RescuedDuration':
      formData['rescuedDuration'],
      'LocationTypeId':
      formData['locationTypeId'] ?? '',
      'SystemDowntime':
      formData['systemDowntime'] ?? '',
      'MeasurementPointIds':
      formData['measurementPointIds'] ?? '',
      'PriorityId':
      formData['priorityId'] ?? 0,
      'AssignedUseeName':
      formData['assignedUseeName'] ?? userName,
      'LocationFailure':
      formData['locationFailure'] ?? '',
      'Corr_NotificationTypeId':
      formData['corrNotificationTypeId'] ?? 0,
      'System':
      formData['system'] ?? '',
      'SubSystem':
      formData['subSystem'] ?? '',
      'Frequency':
      formData['frequency'] ?? 0,
    };

    debugPrint("Formatted Request Body: $requestBody");

    // ACTUAL API CALL
    final failureNo = await createMaintenanceFailure(requestBody);

    debugPrint("Created Maintenance Failure No: $failureNo");

    return {
      'responseCode': 200,
      'responseMessage': 'Success',
      'responseOutput': failureNo,
    };
  }


  Future<FailureDetailResponse> getMaintenanceFailureDetails(
      List<String> ids) async {
    final userId = await _userId();
    FailureDetailResponse? last;
    for (final id in ids.where((e) => e.trim().isNotEmpty).toSet()) {
      for (final uid in {userId, 0}) {
        final body = {'AssignedUserId': uid, 'Id': id};
        debugPrint('SI details try: $body');
        final response =
        await _apiClient.post(AppUrls.jeChangeNotification, body: body);
        if (response.statusCode != 200) continue;
        final parsed = FailureDetailResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        last = parsed;
        if (parsed.responseOutput?.getCreateVMModel != null) {
          debugPrint('SI details: model found with $body');
          return parsed;
        }
      }
    }
    if (last != null) return last;
    throw Exception('No response for failure details');
  }


  Future<Map<String, dynamic>> updateMaintenanceFailure(
      Map<String, dynamic> payload) async {
    final headers = await _authHeaders();

    debugPrint("updateMaintenanceFailure: API endpoint: ${AppUrls.editNotificationDetails}");
    debugPrint("updateMaintenanceFailure: Request payload: $payload");

    final response = await _apiClient.postMultipart(
      AppUrls.editNotificationDetails,
      headers: headers,
      fields: {
        'CreateNotificationVM': jsonEncode(payload),
      },
    );

    debugPrint("updateMaintenanceFailure: Response status: ${response.statusCode}");
    debugPrint("updateMaintenanceFailure: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Failed to update maintenance failure: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] != 200) {
      throw Exception(
        body['responseMessage'] ?? 'Failed to update maintenance failure',
      );
    }
    return body;
  }

  Future<String?> createMaintenanceFailure(
      Map<String, dynamic> payload) async {
    final headers = await _authHeaders();

    debugPrint(
        "createMaintenanceFailure: API endpoint: ${AppUrls.createNotificationDetails}");
    debugPrint("createMaintenanceFailure: Request headers: $headers");
    debugPrint("createMaintenanceFailure: Request payload: $payload");

    final response = await _apiClient.postMultipart(
      AppUrls.createNotificationDetails,
      headers: headers,
      fields: {
        'CreateNotificationVM': jsonEncode(payload),
      },
    );

    debugPrint(
        "createMaintenanceFailure: Response status: ${response.statusCode}");
    debugPrint(
        "createMaintenanceFailure: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create maintenance failure: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['responseCode'] != 200) {
      throw Exception(
        body['responseMessage'] ??
            'Failed to create maintenance failure',
      );
    }

    return body['responseOutput']?.toString();
  }

  /// Updates Station Acknowledge Status (Accept / Deny / Re-open / Close)
  Future<Map<String, dynamic>> updateStationAcknowledgeStatus({
    required int id,
    required String action,
    required String description,
    required int statusId,
    required int createdBy,
    required String createdByName,
  }) async {
    final response = await _apiClient.post(
      AppUrls.updateStationAcknowledgeStatus,
      body: {
        "Id": id,
        "StatusId": statusId,
        "Action": action,
        "CreatedBy": createdBy,
        "CreatedByName": createdByName,
        "Description": description,
      },
    );

    debugPrint(
        "updateStationAcknowledgeStatus: Status ${response.statusCode}, Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Server error: ${response.statusCode}');
  }


  Future<bool> closeNotification({
    required String jobCardNo,
    required int assignedUserId,
  }) async {
    final userId = await _userId();

    final body = {
      'JobCardNo': jobCardNo,
      'AssignedUserId': assignedUserId,
      'CreatedBy': userId,
    };

    debugPrint("closeNotification: Request body: $body");

    final response = await _apiClient.post(
      AppUrls.updateCloseStatusNotification,
      body: body,
    );

    debugPrint("closeNotification: Response status: ${response.statusCode}");
    debugPrint("closeNotification: Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return responseBody['responseCode'] == 200 &&
        responseBody['responseOutput'] == true;
  }
}
