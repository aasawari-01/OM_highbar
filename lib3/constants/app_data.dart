import 'package:intl/intl.dart';

// ── Station Equipment Categories ─────────────────────────────────────────────
const List<String> equipmentCategories = [
  'ATS HMI',
  'CCTV Work Station',
  'PIDS',
  'PAS',
  'PIDS/PAS Work Station',
  'Tetra',
  'Radio Control Panel',
  'IP Phone',
  'DLT Phone',
  'BSNL',
  'BMS Work Station',
  'FACP',
  'Lift',
  'Escalator',
  'Passenger Help Point',
  'Lift InterCom',
  'Tom',
  'EFO',
  'AFC Gate',
  'Station Computer',
  'TVM Equipemnt',
  'ESP',
  'MCP',
  'Baggage Scanner',
  'DFMD',
  'HHMD',
];

List<Map<String, dynamic>> equipmentStatusList = equipmentCategories
    .map((category) => {'category': category, 'workStatus': true, 'remark': ''})
    .toList();

// ── Stock Categories ──────────────────────────────────────────────────────────
const List<String> stockCategories = [
  'QR',
  'Wax Roll',
  'Print Receipt',
  'Maha Card',
  'TVM Roll',
  'TVM receipt print roll',
  'TOM receipt print roll',
  'Others',
];

// ── Material Types ────────────────────────────────────────────────────────────
const List<String> materialTypeList = [
  'Software',
  'Hardware',
  'Communication',
  'Other',
];

// ── Utility Functions ─────────────────────────────────────────────────────────
/// Formats a [DateTime] to 'dd/MM/yyyy'.
String formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// Formats a [DateTime] to 'dd/MM/yyyy HH:mm'.
String formatDateTime(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);
