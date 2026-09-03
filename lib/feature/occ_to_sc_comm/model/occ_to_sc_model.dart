/// Models matching the OCC-to-SC master-data API response shape:
///
/// {
///   "instructionTypes": [{ "id": 1, "name": "General" }, ...],
///   "instructionBy":    [{ "id": 1, "name": "ED" }, ...],
///   "departments":      [{ "id": 1, "name": "Signalling",
///                           "systems": [{ "id": 101, "name": "CBTC" }] }],
///   "emergencyTypes":   [{ "id": 1, "name": "Fire" }],
///   "lines":            [{ "id": 1, "name": "Line 1",
///                           "stations": [{ "id": 101, "name": "Station A",
///                                          "stationType": "Elevated" }] }]
/// }
class OccToScMasterDataResponse {
  final bool success;
  final String message;
  final OccToScMasterData data;

  OccToScMasterDataResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OccToScMasterDataResponse.fromJson(Map<String, dynamic> json) {
    return OccToScMasterDataResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: OccToScMasterData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class OccToScMasterData {
  final List<MasterDataItem> instructionTypes;
  final List<MasterDataItem> instructionBy;
  final List<DepartmentModel> departments;
  final List<MasterDataItem> emergencyTypes;
  final List<LineModel> lines;

  OccToScMasterData({
    required this.instructionTypes,
    required this.instructionBy,
    required this.departments,
    required this.emergencyTypes,
    required this.lines,
  });

  factory OccToScMasterData.fromJson(Map<String, dynamic> json) {
    return OccToScMasterData(
      instructionTypes: (json['instructionTypes'] as List?)
          ?.map(
            (e) => MasterDataItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
      instructionBy: (json['instructionBy'] as List?)
          ?.map(
            (e) => MasterDataItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
      departments: (json['departments'] as List?)
          ?.map(
            (e) => DepartmentModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
      emergencyTypes: (json['emergencyTypes'] as List?)
          ?.map(
            (e) => MasterDataItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
      lines: (json['lines'] as List?)
          ?.map(
            (e) => LineModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
    );
  }
}

class MasterDataItem {
  final int id;
  final String name;

  MasterDataItem({
    required this.id,
    required this.name,
  });

  factory MasterDataItem.fromJson(Map<String, dynamic> json) {
    return MasterDataItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class DepartmentModel {
  final int id;
  final String name;
  final List<SystemModel> systems;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.systems,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      systems: (json['systems'] as List?)
          ?.map(
            (e) => SystemModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
    );
  }
}

class SystemModel {
  final String name;

  SystemModel({
    required this.name,
  });

  factory SystemModel.fromJson(Map<String, dynamic> json) {
    return SystemModel(
      name: json['name']?.toString() ?? '',
    );
  }
}

class LineModel {
  final int id;
  final String name;
  final List<StationModel> stations;

  LineModel({
    required this.id,
    required this.name,
    required this.stations,
  });

  factory LineModel.fromJson(Map<String, dynamic> json) {
    return LineModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      stations: (json['stations'] as List?)
          ?.map(
            (e) => StationModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList() ??
          [],
    );
  }
}

class StationModel {
  final int id;
  final String name;
  final String stationType;

  StationModel({
    required this.id,
    required this.name,
    required this.stationType,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      stationType: json['stationType']?.toString() ?? '',
    );
  }
}


class OccInstructionSubmitResponse {
  final bool success;
  final String message;
  final int? instructionId;

  OccInstructionSubmitResponse({
    required this.success,
    required this.message,
    this.instructionId,
  });

  factory OccInstructionSubmitResponse.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];

    int? id;
    if (data is Map<String, dynamic>) {
      id = data['id'] is int
          ? data['id']
          : int.tryParse(data['id']?.toString() ?? '');
    }

    return OccInstructionSubmitResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      instructionId: id,
    );
  }
}