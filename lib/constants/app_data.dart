import 'package:intl/intl.dart';

// Department List
const List<Map<String, dynamic>> departmentList = [
  {'id': 10, 'value': 'Signalling'},
  {'id': 20, 'value': 'Telecom'},
  {'id': 30, 'value': 'Rolling Stock'},
  {'id': 40, 'value': 'Electrical and Mechanical'},
  {'id': 50, 'value': 'Lift and Escalator'},
  {'id': 60, 'value': 'Track'},
  {'id': 70, 'value': 'Information Technology'},
  {'id': 80, 'value': 'Civil'},
  {'id': 90, 'value': 'Overhead Equipment'},
  {'id': 100, 'value': 'Power Supply'},
  {'id': 110, 'value': 'Human Resources'},
  {'id': 120, 'value': 'Operation Chief Controller'},
  {'id': 130, 'value': 'Security Surveillance System'},
  {'id': 140, 'value': 'Depot Equipment'},
  {'id': 150, 'value': 'Finance'},
  {'id': 160, 'value': 'AFC'},
  {'id': 170, 'value': 'Station Operation'},
  {'id': 180, 'value': 'Crew Management System'},
  {'id': 190, 'value': 'Finance'},
  {'id': 200, 'value': 'Safety'},
  {'id': 210, 'value': 'Solar'},
  {'id': 220, 'value': 'Customer Relationship Management'},
];
final List<String> departmentListValue = departmentList.map((e) => e['value'] as String).toList();

const List<Map<String, dynamic>> directionList = [
  {'id': 1, 'value': 'Up Line'},
  {'id': 2, 'value': 'Down Line'},
];
final List<String> directionListValue = directionList.map((e) => e['value'] as String).toList();

const List<Map<String, dynamic>> stationList = [
  {'id': 1, 'value': 'Khapri'},
  {'id': 2, 'value': 'New Airport'},
  {'id': 3, 'value': 'Airport South'},
  {'id': 4, 'value': 'Airport'},
  {'id': 5, 'value': 'Ujjwal Nagar'},
  {'id': 6, 'value': 'Jaiprakash Nagar'},
  {'id': 7, 'value': 'Chhatrapati Square'},
  {'id': 8, 'value': 'Ajni Square'},
  {'id': 9, 'value': 'Ajni Square'},
  {'id': 10, 'value': 'Rancha Colony'},
  {'id': 11, 'value': 'Congress Nagar'},
  {'id': 12, 'value': 'Sita Buldi'},
  {'id': 13, 'value': 'Chhatrapati Square'},
  {'id': 14, 'value': 'Ajni Square'},
  {'id': 15, 'value': 'Airport South'},
  {'id': 16, 'value': 'Chhatrapati Square'},
  {'id': 17, 'value': 'Airport South'},
  {'id': 18, 'value': 'Rancha Colony'},
];
final List<String> stationListValue = stationList.map((e) => e['value'] as String).toList();

const List<Map<String, dynamic>> priorityList = [
  {'id': 1, 'value': 'Low'},
  {'id': 2, 'value': 'Medium'},
  {'id': 3, 'value': 'High'},
];
final List<String> priorityListValue = priorityList.map((e) => e['value'] as String).toList();
List <String> personList=['Pooja Sharma', 'Saisha Jain', 'Tejas Varma'];
const List<Map<String, dynamic>> equipmentNumberList = [
  {'id': 1, 'value': 'Equipment 1'},
  {'id': 2, 'value': 'Equipment 2'},
  {'id': 3, 'value': 'Equipment 3'},
  {'id': 4, 'value': 'Equipment 4'},
  {'id': 5, 'value': 'Equipment 5'},
];
final List<String> equipmentNumberListValue = equipmentNumberList.map((e) => e['value'] as String).toList();

// Add feedbackTypes and feedbackTypesValue
const List<Map<String, dynamic>> feedbackTypes = [
  {'id': 1, 'value': 'Complaints'},
  {'id': 2, 'value': 'Suggestions'},
  {'id': 3, 'value': 'Appreciation'},
  {'id': 4, 'value': 'Neutral'},
  {'id': 5, 'value': 'Enquiry'},
];
final List<String> feedbackTypesValue = feedbackTypes.map((e) => e['value'] as String).toList();

// Add complaintTypes and complaintTypesValue
const List<Map<String, dynamic>> complaintTypes = [
  {'id': 1, 'value': 'Staff Complaints'},
  {'id': 2, 'value': 'Security/Safety'},
  {'id': 3, 'value': 'Ticket/Revenue'},
  {'id': 4, 'value': 'MMI/PD'},
  {'id': 5, 'value': 'Train Operation'},
  {'id': 6, 'value': 'E&M'},
  {'id': 7, 'value': 'Rolling Stock'},
  {'id': 8, 'value': 'Telecom'},
  {'id': 9, 'value': 'Civil'},
  {'id': 10, 'value': 'Station Operations'},
  {'id': 11, 'value': 'Information Technology'},
  {'id': 12, 'value': 'Miscellaneous'},
];
final List<String> complaintTypesValue = complaintTypes.map((e) => e['value'] as String).toList();

// Add sourceList and sourceListValue
const List<Map<String, dynamic>> sourceList = [
  {'id': 1, 'value': 'Email'},
  {'id': 2, 'value': 'Phone'},
  {'id': 3, 'value': 'SMS'},
  {'id': 4, 'value': 'Personal Visit'},
  {'id': 5, 'value': 'Dropbox'},
  {'id': 6, 'value': 'QR'},
];
final List<String> sourceListValue = sourceList.map((e) => e['value'] as String).toList();

// Add staffComplaintCategories and staffComplaintCategoriesValue
const List<Map<String, dynamic>> staffComplaintCategories = [
  {'id': 1, 'value': 'Misbehaviour'},
  {'id': 2, 'value': 'Wrong Ticket / Overcharging by TOM Operator'},
  {'id': 3, 'value': 'Train Pilot not opening door / Improper driving'},
  {'id': 4, 'value': 'Announcement not made'},
  {'id': 5, 'value': 'Improper frisking by security staff'},
  {'id': 6, 'value': 'Other'},
];
final List<String> staffComplaintCategoriesValue = staffComplaintCategories.map((e) => e['value'] as String).toList();

// Example utility function: formatDate
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

// Example: calculateDateDifference
int calculateDateDifference(String startDate, String endDate, {String unit = 'days'}) {
  DateTime parseDate(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length != 3) throw Exception('Invalid date format');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
    return DateTime(year, month, day);
  }
  final start = parseDate(startDate);
  final end = parseDate(endDate);
  switch (unit) {
    case 'days':
      return end.difference(start).inDays + 1;
    case 'months':
      return (end.year - start.year) * 12 + (end.month - start.month);
    case 'years':
      return end.year - start.year;
    default:
      throw Exception('Invalid unit');
  }
}


// Add categories and dataList for station equipment
const List<String> categories = [
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

final List<Map<String, dynamic>> dataList = List.generate(categories.length, (index) => {
  'srNo': {'value': index + 1, 'styleClass': ''},
  'category': {'value': categories[index], 'styleClass': ''},
  'workStatus': {'value': 1, 'styleClass': ''},
  'remark': {'value': '', 'styleClass': ''},
});

List<Map<String, dynamic>> equipmentStatusList = [
  {'category': 'ATS HMI', 'workStatus': true, 'remark': ''},
  {'category': 'CCTV Work Station', 'workStatus': true, 'remark': ''},
  {'category': 'PIDS', 'workStatus': true, 'remark': ''},
  {'category': 'PAS', 'workStatus': true, 'remark': ''},
  {'category': 'PIDS/PAS Work Station', 'workStatus': true, 'remark': ''},
  {'category': 'Tetra', 'workStatus': true, 'remark': ''},
  {'category': 'Radio Control Panel', 'workStatus': true, 'remark': ''},
  {'category': 'IP Phone', 'workStatus': true, 'remark': ''},
  {'category': 'DLT Phone', 'workStatus': true, 'remark': ''},
  {'category': 'BSNL', 'workStatus': true, 'remark': ''},
  {'category': 'BMS Work Station', 'workStatus': true, 'remark': ''},
  {'category': 'FACP', 'workStatus': true, 'remark': ''},
  {'category': 'Lift', 'workStatus': true, 'remark': ''},
  {'category': 'Escalator', 'workStatus': true, 'remark': ''},
  {'category': 'Passenger Help Point', 'workStatus': true, 'remark': ''},
  {'category': 'Lift InterCom', 'workStatus': true, 'remark': ''},
  {'category': 'Tom', 'workStatus': true, 'remark': ''},
  {'category': 'EFO', 'workStatus': true, 'remark': ''},
  {'category': 'AFC Gate', 'workStatus': true, 'remark': ''},
  {'category': 'Station Computer', 'workStatus': true, 'remark': ''},
  {'category': 'TVM Equipemnt', 'workStatus': true, 'remark': ''},
  {'category': 'ESP', 'workStatus': true, 'remark': ''},
  {'category': 'MCP', 'workStatus': true, 'remark': ''},
  {'category': 'Baggage Scanner', 'workStatus': true, 'remark': ''},
  {'category': 'DFMD', 'workStatus': true, 'remark': ''},
  {'category': 'HHMD', 'workStatus': true, 'remark': ''},
];

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

