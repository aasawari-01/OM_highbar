import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:om_mobile/core/controller/session_controller.dart';
import 'package:om_mobile/service/auth_manager.dart';
import 'package:om_mobile/service/master_data_sync_service.dart';

import '../model/dashboard_models.dart';
import '../service/dashboard_service.dart';

/// State of the dashboard. It re-reads the local failure data whenever
/// something that can change it happens: the user switches role / department /
/// station / depot, a sync finishes, the connection changes, or the user pulls
/// down to refresh. The offline queue is also re-read every few seconds.
class DashboardController extends GetxController {
  DashboardController({
    DashboardService? service,
    SessionController? session,
    MasterDataSyncService? syncService,
  })  : _service = service ?? DashboardService(),
        _session = session ?? Get.find<SessionController>(),
        _sync = syncService ?? Get.find<MasterDataSyncService>();

  final DashboardService _service;
  final SessionController _session;
  final MasterDataSyncService _sync;

  static const Duration _queueRefresh = Duration(seconds: 5);
  static const Duration _dataRefresh = Duration(seconds: 60);

  final Rx<DashboardSummary> summary = const DashboardSummary.empty().obs;
  final Rx<DashboardQueue> queue = const DashboardQueue.empty().obs;
  final RxBool isOnline = true.obs;
  final RxBool isLoading = true.obs;
  final Rxn<DateTime> lastUpdated = Rxn<DateTime>();

  /// The sync running now (from the sync service).
  RxBool get isSyncing => _sync.isSyncing;

  final List<Worker> _workers = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timer;
  int _ticks = 0;
  bool _loading = false;
  bool _loadAgain = false;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever(_session.selectedRole, (_) => load()),
      ever(_session.selectedDepartment, (_) => load()),
      ever(_session.selectedStationId, (_) => load()),
      ever(_session.selectedDepotId, (_) => load()),
      // A finished sync brought new data and sent the waiting items.
      ever<bool>(_sync.isSyncing, (syncing) {
        if (!syncing) refreshAll();
      }),
    ]);
    _watchConnection();
    _timer = Timer.periodic(_queueRefresh, (_) => _onTick());
    refreshAll();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _connectivity?.cancel();
    for (final w in _workers) {
      w.dispose();
    }
    super.onClose();
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> refreshAll() async {
    await Future.wait([load(), loadQueue()]);
  }

  /// Pull to refresh: brings the latest data from the server first when online.
  Future<void> pullToRefresh() async {
    if (isOnline.value && !_sync.isSyncing.value) {
      try {
        await _sync.syncFailureTransactions();
      } catch (e) {
        debugPrint('DashboardController.pullToRefresh: $e');
      }
    }
    await refreshAll();
  }

  /// Same as the sync button: master data, failures, then the waiting queue.
  Future<void> syncNow() async {
    if (_sync.isSyncing.value) return;
    await _sync.syncMasterAndPending();
  }

  Future<void> load() async {
    // One read at a time; a change that comes during a read triggers one more.
    if (_loading) {
      _loadAgain = true;
      return;
    }
    _loading = true;
    try {
      do {
        _loadAgain = false;
        final role = _session.selectedRole.value?.roleDescr ?? '';
        final userId = int.tryParse(await AuthManager().getUserId() ?? '') ?? 0;
        summary.value = await _service.loadSummary(
          scope: DashboardService.scopeFor(role),
          userId: userId,
          deptId: _session.selectedDepartment.value?.deptId ?? 0,
          stationId: _session.selectedStationId.value,
          depotId: int.tryParse(_session.selectedDepotId.value ?? '') ?? 0,
        );
        lastUpdated.value = DateTime.now();
      } while (_loadAgain);
    } finally {
      _loading = false;
      isLoading.value = false;
    }
  }

  Future<void> loadQueue() async {
    queue.value = await _service.loadQueue(await AuthManager().getUserId());
  }

  // ── Live updates ─────────────────────────────────────────────────────────

  void _onTick() {
    _ticks++;
    loadQueue();
    // The failure data is read again less often (it is bigger).
    if (_ticks % (_dataRefresh.inSeconds ~/ _queueRefresh.inSeconds) == 0) {
      load();
    }
  }

  void _watchConnection() {
    bool online(List<ConnectivityResult> r) =>
        r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.mobile) ||
        r.contains(ConnectivityResult.ethernet);

    Connectivity().checkConnectivity().then((r) => isOnline.value = online(r));
    _connectivity = Connectivity()
        .onConnectivityChanged
        .listen((r) => isOnline.value = online(r));
  }
}
