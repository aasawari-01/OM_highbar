import 'package:om_mobile/feature/failure/service/failure_log.dart';
import 'package:get/get.dart';
import '../../../constants/strings.dart';
import '../../../core/controller/session_controller.dart';
import '../../../service/local_database_service.dart';
import '../../../service/master_data_sync_service.dart';
import '../model/rst_list_response.dart';
import '../service/failure_service.dart';
import '../service/rst_offline_service.dart';
import '../service/rst_record_mapper.dart';
import '../service/rst_submit_helper.dart';
import '../view/shared/failure_toast.dart';
import '../../../service/network_service/app_urls.dart';

/// The RST list. It reads the local copy of GetRstFailureTrasactionDetails
/// (downloaded at login and by the sync button), so it works offline; failures
/// created on the device and not sent yet come first as "Pending Sync".
class RstListController extends GetxController {
  final LocalDatabaseService _db = LocalDatabaseService();
  final FailureService _failureService = FailureService();

  final RxList<RstItem> rstItems = <RstItem>[].obs;
  final RxString searchQuery = "".obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = "".obs;

  String get _role => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().selectedRole.value?.roleDescr ?? ''
      : '';

  /// The PPIO creates, assigns and closes RST failures.
  bool get isPpio => SessionController.isRstPpioRole(_role);

  List<RstItem> get filteredRstItems {
    if (searchQuery.value.trim().isEmpty) return rstItems;
    final q = searchQuery.value.trim().toLowerCase();
    return rstItems.where((item) {
      final code = (item.notificationCode ?? '').toLowerCase();
      final plant = (item.plantName ?? '').toLowerCase();
      final trainSet = (item.trainSetNo ?? '').toLowerCase();
      final status = (item.statusName ?? '').toLowerCase();
      return code.contains(q) || plant.contains(q) || trainSet.contains(q) || status.contains(q);
    }).toList();
  }

  /// [sync]: ask the server for the latest first (pull to refresh, sync button).
  Future<void> fetchRstList({bool sync = false}) async {
    isLoading.value = true;
    errorMessage.value = "";

    try {
      final syncService = Get.find<MasterDataSyncService>();
      if (sync) {
        await syncService.syncRstFailures();
        await _loadFromCache();
      } else {
        // Show the local copy at once, then refresh it from the server when
        // there is internet (the sync fails quietly when offline).
        await _loadFromCache();
        isLoading.value = false;
        final ok = await syncService.syncRstFailures();
        if (ok != false) await _loadFromCache();
      }
    } catch (e) {
      failureLog('fetchRstList: $e');
      errorMessage.value = "Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  /// Does the failure's roleName (e.g. "PPIO, JE") include the logged-in role?
  /// A record without roleName, or a role that is neither PPIO nor JE, is shown.
  bool _visibleForRole(Map<String, dynamic> record) {
    final failure = record['failure'];
    final names = failure is Map ? '${failure['roleName'] ?? ''}'.trim() : '';
    if (names.isEmpty) return true;
    final role = _role;
    final isPpio = SessionController.isRstPpioRole(role);
    final isJe = SessionController.isRstJeRole(role);
    if (!isPpio && !isJe) return true;
    for (final n in names.split(',')) {
      final t = n.trim().toUpperCase();
      if (t == 'PPIO' && isPpio) return true;
      if ((t == 'JE' || t.contains('JUNIOR ENGINEER')) && isJe) return true;
      if (t.isNotEmpty && t != 'PPIO' && t != 'JE' && !t.contains('JUNIOR ENGINEER')) {
        return true; // some other role name: do not hide it
      }
    }
    return false;
  }

  Future<void> _loadFromCache() async {
    {
      final rows = await _db.getRstFailureCache();
      final items = <RstItem>[];
      for (final e in await _db.getRstOfflineEntries()) {
        items.add(RstItem(
          notificationId: e['id'] as int?,
          notificationCode: e['failureNo']?.toString(),
          failureDescription: e['failureDescription']?.toString(),
          funcDescription: e['functionalLocation']?.toString(),
          actualFailureOccuranceOn: e['failureOccuranceDateTime']?.toString(),
          statusName: e['statusName']?.toString(),
          pendingError: (e['syncStatus'] == 'failed') ? e['remarks']?.toString() : null,
          isOfflineCreate: true,
        ));
      }
      for (final row in rows) {
        final record = Map<String, dynamic>.from(row['record'] as Map);
        final failure = record['failure'];
        if (failure is Map && RstRecordMapper.asBool(failure['isDeleted']) == true) {
          continue;
        }
        if (!_visibleForRole(record)) continue;
        items.add(RstRecordMapper.toListItem(
          record,
          pendingAction: row['pendingAction'] as String?,
          pendingError: row['pendingError'] as String?,
        ));
      }
      rstItems.assignAll(items);
    }
  }

  String _target(RstItem item) =>
      (item.notificationEncryptId ?? '').isNotEmpty
          ? item.notificationEncryptId!
          : (item.id ?? '${item.notificationId ?? 0}');

  /// Part G: the PPIO closes a failure the Junior Engineer has completed.
  Future<void> closeFailure(RstItem item) async {
    final userId = await _failureService.getUserId();
    await _run(
      item,
      RstOfflineService.actionClose,
      () => RstSubmitHelper().submit(
        action: RstOfflineService.actionClose,
        endpoint: AppUrls.updateCloseStatusNotification,
        asJson: true,
        notificationId: item.notificationId ?? 0,
        body: {
          'JobCardNo': _target(item),
          'AssignedUserId': 0,
          'CreatedBy': userId,
        },
      ),
      'Failure ${item.notificationCode} closed.',
    );
  }

  Future<void> deleteFailure(RstItem item) async {
    final userId = await _failureService.getUserId();
    await _run(
      item,
      RstOfflineService.actionDelete,
      () => RstSubmitHelper().submit(
        action: RstOfflineService.actionDelete,
        endpoint: AppUrls.updateRSTNotificationDeleteStatus,
        asJson: true,
        notificationId: item.notificationId ?? 0,
        body: {
          'NotificationId': 0,
          'NotificationEncryptId': _target(item),
          'UserId': userId,
          'Description': 'Deleted By User',
        },
      ),
      'Failure ${item.notificationCode} deleted.',
    );
  }

  Future<void> _run(RstItem item, String action,
      Future<RstSubmitResult> Function() send, String doneMessage) async {
    if (item.isOfflineCreate) {
      FailureToast.show(AppStrings.error,
          'This failure is waiting to be sent. Do this after it is synced.');
      return;
    }
    isLoading.value = true;
    try {
      final result = await send();
      FailureToast.show(
          AppStrings.success,
          result.queued
              ? '${RstOfflineService.label(action)} saved on this device. It is sent when the internet is back.'
              : doneMessage);
      await fetchRstList(sync: !result.queued);
    } catch (e) {
      FailureToast.show(AppStrings.error, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
}
