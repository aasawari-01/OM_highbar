import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum IblPartStatus { completed, inProcess, pending }

class IblController extends GetxController {
  final isPartAExpanded = true.obs;
  final isPartA1Expanded = false.obs;
  final isPartBExpanded = false.obs;
  final isPartCExpanded = false.obs;
  final isPartDExpanded = false.obs;
  final isPartD1Expanded = false.obs;
  final isPartEExpanded = false.obs;

  final purposeOfWorkController = TextEditingController();
  final assignIicRemarkController = TextEditingController();

  final selectedDepot = RxnString('Mihan Depot (Nagpur)');
  final selectedIblLineNo = RxnString('IBL 1 - Mihan Depot (Nagpur)');
  final selectedTrainset = RxnString('TRAIN SET 1');
  final selectedAssignIicDischarging = RxnString();
  final selectedAssignIicCharging = RxnString();

  final fromDateTime = Rxn<DateTime>();
  final toDateTime = Rxn<DateTime>();
  final extensionDateTime = Rxn<DateTime>();

  final isDeclarationPartB = false.obs;
  final isDeclarationPartC = false.obs;
  final isDeclarationPartD = false.obs;

  final partBChecks = <bool>[false, false, false, false, false].obs;
  final partEChecks = <bool>[false, false, false, false, false].obs;

  final depotList = ['Mihan Depot (Nagpur)', 'Depot 2'];
  final iblLineList = ['IBL 1 - Mihan Depot (Nagpur)', 'IBL 2 - Mihan Depot (Nagpur)'];
  final trainsetList = ['TRAIN SET 1', 'TRAIN SET 2'];
  final iicList = ['Mr. Yashwantrao Hajare - 00000844', 'Mr. Chirag Paswan - 001239'];

  static const partBInstructions = [
    'Before moving for OHE de-energisation, ensure that All pantograph on the train is in lowered position',
    'Open OHE isolator of the concerned bay line & lock the isolator box with Padlock',
    'Visually ensured that double pole isolator is in open position and single pole earthing heel(rod) is in closed position.',
    'Ensure discharge rod clamps are tightened only after removing the rust from the concerned rails & secured properly.',
    'Discharge rod is applied/hanged nearest to isolator pole of de-energise section of concerned OHE line.',
  ];

  static const partEInstructions = [
    'IIC shall ensure that Part D & Part E is properly signed by sub applicant & Applicant(EPIC) as well as PPIO for clearance of shadow power block.',
    'All person, tools, material are clear from OHE line, Roof platform & concerned roof access gate is in locked position.',
    'Before moving for OHE energisation, ensure that all pantographs of concerned train are in lowered position closed position.',
    'Discharge rod & rail clamps at the concerned OHE line has been removed.',
    'Isolator is being closed & isolator box is pad locked.',
  ];

  static const partBDeclaration =
      'I hereby declare that the above power block is in place and the OHE Line No IBL 1 has been isolated.';

  static const partCDeclaration =
      'I hereby confirms that I have received power block as per the requirement. We will work with due precaution and will follow the work procedure related to our work. I have checked that earthing rod is placed at IBL 1. For which power block has been requested and is properly earthed';

  static const partDDeclaration =
      'I hereby declare that all person/material under my supervision including shadow power block staff have been removed from the train and work area/line is fit for use and no infringement or unsafe condition have been caused by these works.';

  String statusLabel(IblPartStatus status) {
    switch (status) {
      case IblPartStatus.completed:
        return 'Completed';
      case IblPartStatus.inProcess:
        return 'In Process';
      case IblPartStatus.pending:
        return 'Pending';
    }
  }

  @override
  void onClose() {
    purposeOfWorkController.dispose();
    assignIicRemarkController.dispose();
    super.onClose();
  }
}
