import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';
import 'package:om_mobile/constants/app_constants.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/core/controller/session_controller.dart';
import 'package:om_mobile/feature/failure/view/failure_list_screen.dart';
import 'package:om_mobile/utils/widgets/cust_text.dart';

import '../controller/dashboard_controller.dart';
import '../model/dashboard_models.dart';
import 'widgets/dashboard_context_card.dart';
import 'widgets/dashboard_recent_card.dart';
import 'widgets/dashboard_stat_tiles.dart';
import 'widgets/dashboard_status_card.dart';
import 'widgets/dashboard_sync_card.dart';
import 'widgets/dashboard_system_chart.dart';

/// Scrollable content of the dashboard. Everything on it is reactive: it
/// redraws when [DashboardController] has new data.
class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.controller,
    required this.session,
  });

  final DashboardController controller;
  final SessionController session;

  void _openList(String listType) {
    if (listType.isEmpty) return;
    Get.to(() => FailureListScreen(failureType: listType));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.orangeColor,
      onRefresh: controller.pullToRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.screenPadding,
          AppConstants.sectionSpacing,
          AppConstants.screenPadding,
          70,
        ),
        children: [
          DashboardContextCard(session: session),
          DashboardSyncCard(controller: controller),
          Obx(() => _failures(controller.summary.value)),
        ],
      ),
    );
  }

  Widget _failures(DashboardSummary s) {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orangeColor),
        ),
      );
    }
    if (!s.hasSource) {
      return const _EmptyState(
        message: 'There is no failure data for the selected role.',
      );
    }
    if (s.total == 0) {
      return Column(
        children: [
          DashboardStatTiles(
            summary: s,
            waiting: controller.queue.value.total,
            onOpenList: () => _openList(s.listType),
          ),
          const _EmptyState(
            message: 'No failures yet. Pull down or tap Sync now to download '
                'the latest data.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(s.title),
        DashboardStatTiles(
          summary: s,
          waiting: controller.queue.value.total,
          onOpenList: () => _openList(s.listType),
        ),
        if (s.statuses.isNotEmpty) DashboardStatusCard(statuses: s.statuses),
        if (s.systems.isNotEmpty) DashboardSystemChart(systems: s.systems),
        if (s.recent.isNotEmpty)
          DashboardRecentCard(
            recent: s.recent,
            onViewAll: () => _openList(s.listType),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.subElementSpacing + 4),
      child: CustText(
        name: title,
        size: AppConstants.headerSize,
        color: AppColors.textDarkPrimary,
        fontWeightName: FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.sectionSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(TablerIcons.inbox, size: 40, color: AppColors.iconColor2),
          const SizedBox(height: AppConstants.subElementSpacing),
          CustText(
            name: message,
            size: AppConstants.bodySize,
            color: AppColors.textDarkSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
