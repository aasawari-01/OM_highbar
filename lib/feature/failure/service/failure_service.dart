import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../../core/models/label_value.dart';
import '../model/rst_failure_full_response.dart';
import '../../../core/models/rst_failure_type.dart';
import '../../../core/models/rst_object_part.dart';
import '../../../core/models/rst_material.dart';
import '../../../core/models/rst_train_status.dart';
import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../../../service/local_database_service.dart';
import '../model/failure_detail_response.dart';
import '../model/joint_inspection_history.dart';



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
    final response = await _apiClient.post(
      AppUrls.jeChangeNotification,
      body: {'AssignedUserId': userId, 'Id': failureNo},
    );
    debugPrint("fetch failure paramet==$userId :: $failureNo");
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return FailureDetailResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
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

  /// Loads station failure details. Returns the raw `responseOutput` map.
  Future<Map<String, dynamic>> getStationFailureDetails(String id) async {
    final userId = await _userId();
    final response = await _apiClient.post(
      AppUrls.getStationFailureCreationById,
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
      throw Exception(body['responseMessage'] ?? 'Failed to load details');
    }
    return body['responseOutput'] as Map<String, dynamic>;
  }

  /// Creates a new station failure. Returns the created failure number.
  Future<String?> createStationFailure(Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final response = await _apiClient.postMultipart(
      AppUrls.createStationFailure,
      headers: headers,
      fields: {'StationFailureCreationDetails': jsonEncode(payload)},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create station failure: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final userId = await AuthManager().getUserId() ?? '1';
    final response = await _apiClient
        .get('${AppUrls.getStationName}?AssgineUserId=$userId');
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['responseCode'] == 200 && body['responseOutput'] != null) {
      return (body['responseOutput'] as List)
          .map((e) => LabelValue(
                label: e['label']?.toString() ?? '',
                value: e['value']?.toString() ?? '',
              ))
          .toList();
    }
    return [];
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
    debugPrint("jsonBody==+$jsonBody");
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
    debugPrint("jsonBody==$jsonBody");
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
  Future<List<LabelValue>> getDeptMasterData() async {
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetDeptMasterData'},
    );
    debugPrint("getDeptMasterData statusCode: ${response.statusCode}");
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint("getDeptMasterData response keys: ${body.keys.toList()}");
    debugPrint("getDeptMasterData full response: $body");

    // Try different response structures
    if (body['responseCode'] == 200 && body['responseOutput'] != null) {
      final departments = body['responseOutput'] as List?;
      if (departments != null) {
        debugPrint("getDeptMasterData found departments in responseOutput: ${departments.length} items");
        return departments
            .map((e) => LabelValue(
                  label: e['deptName']?.toString() ?? e['label']?.toString() ?? '',
                  value: e['deptId']?.toString() ?? e['value']?.toString() ?? '',
                ))
            .toList();
      }
    }

    if (body['success'] == true && body['data'] != null) {
      final departments = body['data']['departments'] as List?;
      if (departments != null) {
        debugPrint("getDeptMasterData found departments in data.departments: ${departments.length} items");
        return departments
            .map((e) => LabelValue(
                  label: e['deptName']?.toString() ?? '',
                  value: e['deptId']?.toString() ?? '',
                ))
            .toList();
      }
    }

    debugPrint("getDeptMasterData: No departments found in response");
    return [];
  }

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
    print("body===$body");
    print("documnents====${body['data']['documents']}");
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

  /// Fetches and stores RST failure types locally
  Future<void> fetchRstFailureTypes() async {
    final dbService = LocalDatabaseService();
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetRSTFailureTypeData'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final failureTypes = (body['data']['failureTypes'] as List?)
                ?.map((e) => RstFailureType.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        await dbService.insertRstFailureTypes(failureTypes);
      }
    }
  }

  /// Fetches and stores RST object parts locally
  Future<void> fetchRstObjectParts() async {
    final dbService = LocalDatabaseService();
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetObjectPartForRST'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final objectParts = (body['data']['objectParts'] as List?)
                ?.map((e) => RstObjectPart.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        await dbService.insertRstObjectParts(objectParts);
      }
    }
  }

  /// Fetches and stores RST materials locally
  Future<void> fetchRstMaterials() async {
    final dbService = LocalDatabaseService();
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetMaterialMasterData'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final materials = (body['data']['materials'] as List?)
                ?.map((e) => RstMaterial.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        await dbService.insertRstMaterials(materials);
      }
    }
  }

  /// Fetches and stores RST storage locations locally
  Future<void> fetchRstStorageLocations() async {
    final dbService = LocalDatabaseService();
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetStorageLocationData'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final storageLocations = (body['data']['storageLocations'] as List?)
            ?.map((e) => LabelValue(
          label: e['storageLocation']?.toString() ?? '',   // ✅ correct source field
          value: e['storageRowId']?.toString() ?? '',       // ✅ correct source field
        ))
            .toList() ??
            [];
        await dbService.insertRstStorageLocations(storageLocations);
      }
    }
  }
  /// Fetches and stores RST train statuses locally
  Future<void> fetchRstTrainStatuses() async {
    final dbService = LocalDatabaseService();
    final response = await _apiClient.post(
      AppUrls.getMasterData,
      body: {'action': 'GetRSTTrainStatusData'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final trainStatuses = (body['data']['trainStatuses'] as List?)
                ?.map((e) => RstTrainStatus.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        await dbService.insertRstTrainStatuses(trainStatuses);
      }
    }
  }

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
    print("body---$body");
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
  Future<void> fetchRstMasterData() async {
    await Future.wait([
      fetchRstFailureTypes(),
      fetchRstObjectParts(),
      fetchRstMaterials(),
      fetchRstTrainStatuses(),
      fetchRstStorageLocations(),
    ]);
  }
}
