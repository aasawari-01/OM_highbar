/// Response of mobileAppAPI/MasterDataLogin and mobileAppAPI/getMasterDataSync:
///
/// {
///   success, message,
///   data: {
///     rowVersion, serverLatest, needFullResync, hasMore, isChanged,
///     data: { locations, equipments, measurementPoints, priorities, plants,
///             departments, failureCategories, rstFailureTypes, objectParts,
///             materials, storageLocations, rstTrainStatuses,
///             notificationTypes, newFailureCategories, newRootCauses,
///             newCausesOfFailure, actionMasters, rootCauseMasters,
///             faultMasters, corrFailureTypes },
///     userData: { users, userChanges }
///   }
/// }
///
/// Every list is kept as the list of maps the server sent; the rows are written
/// to the local master tables by LocalDatabaseService (see the upsert methods).
class MasterDataResponse {
  final bool success;
  final String? message;

  /// The version of the data in this response: sent back to getMasterDataSync
  /// to get only what changed after it.
  final int? rowVersion;
  final int? serverLatest;

  /// The server asks for a full download (MasterDataLogin with a null version).
  final bool needFullResync;

  /// More pages follow: call getMasterDataSync again with [rowVersion].
  final bool hasMore;
  final bool isChanged;

  final Map<String, List<dynamic>> lists;

  /// The full user list (rows of user, role and department) when the server
  /// sends it.
  final List<dynamic> users;

  /// What changed for the users since the version asked for: one entry per user
  /// {userId, action, addedRights, removedRights}. The action is DELETE, NEW,
  /// NO_RIGHTS, UPSERT or RIGHTS (see LocalDatabaseService.applyUserChanges).
  final List<dynamic> userChanges;

  const MasterDataResponse({
    required this.success,
    this.message,
    this.rowVersion,
    this.serverLatest,
    this.needFullResync = false,
    this.hasMore = false,
    this.isChanged = true,
    this.lists = const {},
    this.users = const [],
    this.userChanges = const [],
  });

  // The lists of the response, by the name the server uses.
  static const String locations = 'locations';
  static const String equipments = 'equipments';
  static const String measurementPoints = 'measurementPoints';
  static const String priorities = 'priorities';
  static const String plants = 'plants';
  static const String departments = 'departments';
  static const String failureCategories = 'failureCategories';
  static const String rstFailureTypes = 'rstFailureTypes';
  static const String objectParts = 'objectParts';
  static const String materials = 'materials';
  static const String storageLocations = 'storageLocations';
  static const String rstTrainStatuses = 'rstTrainStatuses';
  static const String notificationTypes = 'notificationTypes';
  static const String newFailureCategories = 'newFailureCategories';
  static const String newRootCauses = 'newRootCauses';
  static const String newCausesOfFailure = 'newCausesOfFailure';
  static const String actionMasters = 'actionMasters';
  static const String rootCauseMasters = 'rootCauseMasters';
  static const String faultMasters = 'faultMasters';
  static const String corrFailureTypes = 'corrFailureTypes';
  static const String functionalLocations = 'functionalLocations';

  List<dynamic> list(String name) => lists[name] ?? const [];

  static int? _int(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));

  factory MasterDataResponse.fromJson(Map<String, dynamic> json) {
    final outer = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final inner = outer['data'] is Map
        ? Map<String, dynamic>.from(outer['data'] as Map)
        : <String, dynamic>{};
    final userData = outer['userData'] is Map
        ? Map<String, dynamic>.from(outer['userData'] as Map)
        : <String, dynamic>{};
    return MasterDataResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      rowVersion: _int(outer['rowVersion']),
      serverLatest: _int(outer['serverLatest']),
      needFullResync: outer['needFullResync'] == true,
      hasMore: outer['hasMore'] == true,
      isChanged: outer['isChanged'] != false,
      lists: {
        for (final e in inner.entries)
          if (e.value is List) e.key: e.value as List,
      },
      users: userData['users'] is List ? userData['users'] as List : const [],
      userChanges:
          userData['userChanges'] is List ? userData['userChanges'] as List : const [],
    );
  }
}
