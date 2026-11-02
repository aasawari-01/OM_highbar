import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../service/auth_manager.dart';
import '../../../service/network_service/api_client.dart';
import '../../../service/network_service/app_urls.dart';
import '../model/api_helpers.dart';
import '../model/buffer_stop.dart';
import '../model/cab_petrolling.dart';
import '../model/checklist_rules.dart';
import '../model/creep_request.dart';
import '../model/dg_log_details.dart';
import '../model/foot_inspection.dart';
import '../model/je_inspection_item.dart';
import '../model/load_details.dart';
import '../model/oms_action.dart';
import '../model/temperature_monitoring.dart';
import '../model/toe_load.dart';
import '../model/pilot_train.dart';
import '../model/weld_inspection.dart';

class InspectionService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthManager().getToken();
    return {
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<int> _userId() async =>
      int.tryParse(await AuthManager().getUserId() ?? '0') ?? 0;

  bool _isSuccess(http.Response res) {
    if (res.statusCode != 200) return false;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['responseMessage'] == 'Success' ||
          body['responseCode'] == 200 ||
          body['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Returns `responseOutput` of a successful call; throws otherwise.
  JsonMap _output(http.Response res) {
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['responseOutput'] as Map);
  }

  Future<List<JEInspectionItem>> getJEInspectionList({
    String source = 'JEInspectionList',
  }) async {
    try {
      final userId = await _userId();
      final response = await _apiClient.post(
        '${AppUrls.getJEInspectionList}?UserId=$userId&source=$source',
        headers: await _authHeaders(),
      );
      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final output = body['responseOutput'];
      final rows = output is Map
          ? output.values.toList()
          : (output is List ? output : const []);
      return rows
          .whereType<Map>()
          .map((e) => JEInspectionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading JE inspection list: $e');
      return [];
    }
  }

  Future<bool> skipInspection({required int id, required String remark}) async {
    try {
      final response = await _apiClient.post(
        AppUrls.skipInspectionById,
        headers: await _authHeaders(),
        body: {'Id': id, 'Remark': remark, 'CreatedBy': await _userId()},
      );
      return _isSuccess(response);
    } catch (e) {
      debugPrint('Error skipping inspection: $e');
      return false;
    }
  }

  // ------------------------------------------------- common checklist

  /// `{_basicDetails, _chk}` for a JE inspection. Throws on failure.
  Future<JsonMap> getCommonInspection(String id) async {
    final res = await _apiClient.post(
      AppUrls.getCommonInspection,
      headers: await _authHeaders(),
      body: {'Id': id},
    );
    return _output(res);
  }

  /// Saves the checklist (multipart). [attachment] is the one new file, if any.
  Future<bool> saveCommonChecklist({
    required String id,
    required String inspectionId,
    required String inspectionName,
    required List<JsonMap> fields,
    required List<JsonMap> headers,
    required List<JsonMap> rows,
    required String overallRemark,
    required List<dynamic> existingAttachments,
    required bool isDraft,
    File? attachment,
  }) async
  {
    // The API wants the new file's metadata as JSON in `AttachmentList` and
    // the binary itself under `OverallInspectionAttachments`.
    final attachmentMeta = <Map<String, dynamic>>[];
    if (attachment != null) {
      final name = attachment.path.split(RegExp(r'[\/]')).last;
      final dot = name.lastIndexOf('.');
      attachmentMeta.add({
        'attachmentId': 0,
        'originalFileName': name,
        'filePath': '',
        'fileExtension': dot >= 0 ? name.substring(dot + 1).toLowerCase() : '',
        'fileSize': await attachment.length(),
      });
    }
    final res = await _apiClient.postMultipart(
      AppUrls.saveCommonInspectionCheckListData,
      headers: await _authHeaders(),
      fields: {
        'Id': id,
        'CreatedBy': (await _userId()).toString(),
        'InspectionId': inspectionId,
        'InspectionName': inspectionName,
        'FieldListData': jsonEncode(stripUiKeys(fields)),
        'TableHeaderList': jsonEncode(stripUiKeys(headers)),
        'TableBodyItems': jsonEncode(stripUiKeys(rows)),
        'OverallInspectionRemark': overallRemark,
        'ExistingAttachments': jsonEncode(existingAttachments),
        'AttachmentList': jsonEncode(attachmentMeta),
        'IsDraft': isDraft.toString(),
      },
      files: [
        if (attachment != null)
          await http.MultipartFile.fromPath(
              'OverallInspectionAttachments', attachment.path),
      ],
    );
    return _isSuccess(res);
  }

  /// Final submit step; call only after [saveCommonChecklist] succeeded.
  Future<bool> markCommonSubmitted(String id) async {
    final res = await _apiClient.post(
      AppUrls.updateIsSavedCommonInspection,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------- BMS

  /// `{getInspectionDate, addBMSDetailsModels}` for a JE inspection. Throws on failure.
  Future<JsonMap> getBmsDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getBMSDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return _output(res);
  }

  Future<bool> saveBms(
      {required JsonMap payload, required bool isDraft}) async {
    final res = await _apiClient.postMultipart(
      isDraft ? AppUrls.insertBMS : AppUrls.insertBMSFinalSubmit,
      headers: await _authHeaders(),
      fields: {
        (isDraft ? 'InsertBMSDetails' : 'InsertBMSFinalDetails'): jsonEncode({
          ...payload,
          'CreatedBy': await _userId(),
        }),
      },
    );
    return _isSuccess(res);
  }

  // ----------------------------------------------------------- DG log book

  Future<DgLogDetails> getDgLogDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getDGLogDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return DgLogDetails.fromJson(_output(res));
  }

  /// Creates the DG log, or updates it when [isUpdate].
  Future<bool> saveDgLog(
      {required JsonMap payload, required bool isUpdate}) async {
    final res = await _apiClient.postMultipart(
      isUpdate ? AppUrls.updateDGLogInspection : AppUrls.insertDGLogInspection,
      headers: await _authHeaders(),
      fields: {
        'DGLog': jsonEncode({...payload, 'CreatedBy': await _userId()}),
      },
    );
    return _isSuccess(res);
  }

  // ----------------------------------------------------------- load details

  Future<LoadDetailsData> getLoadDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getLoadDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return LoadDetailsData.fromJson(_output(res));
  }

  /// Saves all load rows. [header] is `addLoadDetails`; `CreatedBy` is added here.
  Future<bool> saveLoadDetails({
    required JsonMap header,
    required List<JsonMap> rows,
  }) async {
    final res = await _apiClient.postMultipart(
      AppUrls.insertLoadDetailsInspection,
      headers: await _authHeaders(),
      fields: {
        'LoadDetails': jsonEncode({
          'getLoadDetails': rows,
          'addLoadDetails': {...header, 'CreatedBy': await _userId()},
        }),
      },
    );
    return _isSuccess(res);
  }

  // -------------------------------------------------------- cab petrolling

  Future<CabPetrollingData> getCabPetrollingDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getCabPetrollingDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return CabPetrollingData.fromJson(_output(res));
  }

  /// Read-only view of a saved cab petrolling (names instead of ids). Throws on failure.
  Future<CabViewData> getCabPetrollingView(String id) async {
    final res = await _apiClient.post(
      AppUrls.getCabPetrollingView,
      headers: await _authHeaders(),
      body: {'CabPetrollingId': id},
    );
    return CabViewData.fromJson(_output(res));
  }

  /// Locations/stations that can be picked for a line's planning plant. Throws on failure.
  Future<List<SelectOption>> getLocations(String planningPlantId) async {
    final res = await _apiClient.post(
      '${AppUrls.getLocationTrainsetDetails}?PlanningPlantId=$planningPlantId',
      headers: await _authHeaders(),
    );
    return apiOptions(_output(res)['getLocationDropDown']);
  }

  /// Saves a cab petrolling with its checklist and the optional [image].
  Future<bool> saveCabPetrolling({
    required JsonMap header,
    required JsonMap checklist,
    File? image,
  }) async
  {
    final res = await _apiClient.postMultipart(
      AppUrls.insertCabPetrollingInspection,
      headers: await _authHeaders(),
      fields: {
        'InspectionVM': jsonEncode({
          'getCabPetrolling': {...header, 'CreatedBy': await _userId()},
          'getCabPetrollingDetail': [checklist],
        }),
      },
      files: [
        if (image != null) await http.MultipartFile.fromPath('beforImage', image.path),
      ],
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------ buffer stop

  Future<BufferStopData> getBufferStopDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getBufferStopDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return BufferStopData.fromJson(_output(res));
  }

  /// Creates the buffer stop with its checklist. [legacy] holds the extra arrays the API expects.
  Future<bool> insertBufferStop({
    required JsonMap header,
    required List<JsonMap> checklist,
    required Map<String, dynamic> legacy,
  }) async {
    final res = await _apiClient.postMultipart(
      AppUrls.insertBufferStopInspection,
      headers: await _authHeaders(),
      fields: {
        'InspectionVM': jsonEncode({
          'getBufferStop': {...header, 'CreatedBy': await _userId()},
          ...legacy,
          'getBufferStopCommonCheckList': checklist,
        }),
      },
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------------ creep

  Future<CreepData> getCreepDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getCreepMeasurementDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return CreepData.fromJson(_output(res));
  }

  /// Max / min rail temperature between [fromTime] and [toTime] on [date]; null on failure.
  Future<({String max, String min})?> getCreepTemperatures({
    required String date,
    required String fromTime,
    required String toTime,
  }) async {
    try {
      final res = await _apiClient.post(
        AppUrls.getCreepMeasurementTimeDetails,
        headers: await _authHeaders(),
        body: {
          'Date': date,
          'FromTime': fromTime,
          'ToTime': toTime,
          'CreatedBy': await _userId(),
        },
      );
      final out = _output(res);
      return (
        max: (out['maxRailTemperature'] ?? '').toString(),
        min: (out['minRailTemperature'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('Error loading creep temperatures: $e');
      return null;
    }
  }

  /// Creates the creep measurement, or updates it when [isUpdate].
  Future<bool> saveCreep({required JsonMap payload, required bool isUpdate}) async {
    final res = await _apiClient.postMultipart(
      isUpdate
          ? AppUrls.updateCreepMeasurementInspection
          : AppUrls.insertCreepMeasurementInspection,
      headers: await _authHeaders(),
      fields: {
        'CreepMeasurementInspection': jsonEncode({...payload, 'CreatedBy': await _userId()}),
      },
    );
    return _isSuccess(res);
  }

  Future<bool> finalSubmitCreep(String id) async {
    final res = await _apiClient.post(
      AppUrls.updateIsSavedCreepMeasurement,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return _isSuccess(res);
  }

  /// Saves only the header fields of a common inspection (JSON), for screens that keep
  /// their own table. The API gets no checklist rows.
  Future<bool> saveCommonFields({required String id, required List<JsonMap> fields}) async {
    final res = await _apiClient.post(
      AppUrls.saveCommonInspectionCheckListData,
      headers: await _authHeaders(),
      body: {
        'Id': id,
        'FieldListData': stripUiKeys(fields),
        'TableBodyItems': [],
        'CreatedBy': await _userId(),
      },
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------- temperature monitoring

  Future<TempData> getTempMonDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getTempMonDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return TempData.fromJson(_output(res));
  }

  /// Reads the readings out of an Excel file. Throws an [Exception] with the server's
  /// message when the file is rejected.
  Future<List<TempRow>> uploadTemperatureFile(File file) async {
    final userId = await _userId();
    final res = await _apiClient.postMultipart(
      AppUrls.getTemperatureUploadData,
      headers: await _authHeaders(),
      fields: {'userId': userId.toString(), 'action': 'GetTemperature_UPLOAD_DATA'},
      files: [await http.MultipartFile.fromPath('_files', file.path)],
    );
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode != 200) {
      final msg = body?['responseOutput'];
      throw Exception(msg is String && msg.isNotEmpty ? msg : 'Error uploading file');
    }
    final data = (body?['responseOutput'] as Map?)?['uploadData'];
    final items = apiList(data);
    return [for (var i = 0; i < items.length; i++) TempRow.fromUpload(i + 1, items[i])];
  }

  /// Saves the readings. [Date] is the inspection date.
  Future<bool> saveTemperature({
    required String inspectionId,
    required String date,
    required String remark,
    required List<TempRow> rows,
  }) async {
    final res = await _apiClient.postMultipart(
      AppUrls.insertTempMonitoringInspection,
      headers: await _authHeaders(),
      fields: {
        'InspectionVM': jsonEncode({
          'getTempMonitoring': rows.map((r) => r.toJson()).toList(),
          'tempMonDetails': {
            'InspectionId': wireId(inspectionId),
            'Date': date,
            'CreatedBy': await _userId(),
            'Remark': remark,
          },
        }),
      },
    );
    return _isSuccess(res);
  }

  /// Marks the temperature monitoring as submitted; call after [saveTemperature] succeeded.
  Future<bool> markTemperatureSubmitted(String inspectionId) async {
    final res = await _apiClient.post(
      '${AppUrls.updateIsSaved}?InspectionId=$inspectionId',
      headers: await _authHeaders(),
      body: {'InspectionId': wireId(inspectionId), 'CreatedBy': await _userId()},
    );
    return _isSuccess(res);
  }

  // -------------------------------------------------------------- toe load

  Future<ToeData> getToeLoadDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getToeLoadDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return ToeData.fromJson(_output(res));
  }

  Future<bool> saveToeLoad({
    required String inspectionId,
    required String date,
    required List<ToeRow> rows,
  }) async {
    final res = await _apiClient.postMultipart(
      AppUrls.insertToeLoadInspection,
      headers: await _authHeaders(),
      fields: {
        'InspectionVM': jsonEncode({
          'getToeLoad': {
            'InspectionId': wireId(inspectionId),
            'Date': date,
            'CreatedBy': await _userId(),
          },
          'getToeLoadDetails': rows.map((r) => r.toJson(date)).toList(),
        }),
      },
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------ OMS action

  Future<OmsData> getOmsDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getOmsActionDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return OmsData.fromJson(_output(res));
  }

  /// Creates the OMS action, or updates it when [isUpdate]. [riFiles] and [accFiles] are
  /// the new attachments for the RI and the acceleration pack.
  Future<bool> saveOms({
    required JsonMap payload,
    required bool isUpdate,
    required List<File> riFiles,
    required List<File> accFiles,
  }) async {
    final res = await _apiClient.postMultipart(
      isUpdate ? AppUrls.updateOmsActionInspection : AppUrls.insertOmsActionInspection,
      headers: await _authHeaders(),
      fields: {
        'OMSActionInspectionDetails': jsonEncode({...payload, 'CreatedBy': await _userId()}),
      },
      files: [
        for (final f in riFiles) await http.MultipartFile.fromPath('OMSImageRI', f.path),
        for (final f in accFiles) await http.MultipartFile.fromPath('OMSImageAcc', f.path),
      ],
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------ foot

  Future<FootData> getFootDetails(String id) async {
    final res = await _apiClient.post(
      AppUrls.getFootInspectionDetails,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return FootData.fromJson(_output(res));
  }

  /// Saves the header fields, then the foot inspection (create, or update when [isUpdate]).
  Future<bool> saveFoot({
    required String id,
    required List<JsonMap> fields,
    required JsonMap payload,
    required bool isUpdate,
  }) async {
    if (!await saveCommonFields(id: id, fields: fields)) return false;
    final res = await _apiClient.postMultipart(
      isUpdate ? AppUrls.updateFootInspection : AppUrls.insertFootInspection,
      headers: await _authHeaders(),
      fields: {
        'FootInspection': jsonEncode({...payload, 'CreatedBy': await _userId()}),
      },
    );
    return _isSuccess(res);
  }

  // ----------------------------------------------------------------- weld

  Future<WeldData> getWeldDetails(String id) async {
    final userId = await _userId();
    final res = await _apiClient.post(
      '${AppUrls.getWeldDetails}?InspectionId=$id&userid=$userId',
      headers: await _authHeaders(),
    );
    return WeldData.fromJson(_output(res));
  }

  /// Saves the header fields, then the weld rows. [status] is 0 for a draft, 1 for submit.
  Future<bool> saveWeld({
    required String id,
    required List<JsonMap> fields,
    required String pointNo,
    required List<WeldRow> rows,
    required int status,
  }) async {
    final userId = await _userId();
    if (!await saveCommonFields(id: id, fields: fields)) return false;
    final res = await _apiClient.postMultipart(
      AppUrls.saveWeldInspection,
      headers: await _authHeaders(),
      fields: {
        'InspectionVM': jsonEncode({
          'InspectionId': id,
          'UserId': userId,
          'Status': status,
          'PointNo': pointNo.isEmpty ? null : pointNo,
          'dtWeldObservationsTable': rows.map((r) => r.toJson()).toList(),
        }),
      },
    );
    return _isSuccess(res);
  }

  // ------------------------------------------------------------ pilot train

  Future<PilotTrainData> getPilotTrainDetail(String id) async {
    final res = await _apiClient.post(
      AppUrls.getPilotTrainDetail,
      headers: await _authHeaders(),
      body: {'JEInspectionId': id, 'CreatedBy': await _userId()},
    );
    return PilotTrainData.fromJson(_output(res));
  }

  /// Creates the pilot train inspection, or updates it when [isUpdate].
  Future<bool> savePilotTrain({
    required JsonMap payload,
    required bool isUpdate,
    File? image,
  }) async {
    final res = await _apiClient.postMultipart(
      isUpdate ? AppUrls.updatePilotTrainInspection : AppUrls.insertPilotTrainInspection,
      headers: await _authHeaders(),
      fields: {
        'PilotTrainInspection': jsonEncode({...payload, 'CreatedBy': await _userId()}),
      },
      files: [
        if (image != null) await http.MultipartFile.fromPath('beforImage', image.path),
      ],
    );
    return _isSuccess(res);
  }
}
