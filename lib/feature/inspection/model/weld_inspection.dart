import 'api_helpers.dart';

const weldRailTypes = <SelectOption>[
  SelectOption('880', '880'),
  SelectOption('1080H', '1080H'),
];

const weldRailPanels = <SelectOption>[
  SelectOption('Left', 'Left'),
  SelectOption('Right', 'Right'),
];

const weldVisualStatuses = <SelectOption>[
  SelectOption('OK', 'OK'),
  SelectOption('NOK', 'NOK'),
];

const weldYesNo = <SelectOption>[
  SelectOption('Yes', 'Yes'),
  SelectOption('No', 'No'),
];

/// One weld observation row (`dtWeldObservationsTable` item).
class WeldRow {
  String weldNo;
  String plinthNo;
  String remark;
  String railType;
  String railPanel;
  String visualStatus;
  String fishplateStatus;
  String documentName;

  /// `data:<mime>;base64,...` as the API stores it; empty when there is no document.
  String document;

  WeldRow({
    this.weldNo = '',
    this.plinthNo = '',
    this.remark = '',
    this.railType = '880',
    this.railPanel = 'Left',
    this.visualStatus = 'OK',
    this.fishplateStatus = 'Yes',
    this.documentName = '',
    this.document = '',
  });

  factory WeldRow.fromJson(Map<String, dynamic> j) {
    String s(String k, [String fallback = '']) {
      final v = (j[k] ?? '').toString();
      return v.isEmpty ? fallback : v;
    }

    return WeldRow(
      weldNo: s('WeldNo'),
      plinthNo: s('PlinthNo'),
      remark: s('Remark'),
      railType: s('RailType', '880'),
      railPanel: s('RailPanel', 'Left'),
      visualStatus: s('VisualStatus', 'OK'),
      fishplateStatus: s('FishPlatStatus', 'Yes'),
      documentName: s('DocumentName'),
      document: s('Document'),
    );
  }

  Map<String, dynamic> toJson() => {
        'WeldNo': weldNo,
        'PlinthNo': plinthNo,
        'Remark': remark,
        'RailType': railType,
        'RailPanel': railPanel,
        'VisualStatus': visualStatus,
        'FishPlatStatus': fishplateStatus,
        'DocumentName': documentName,
        'Document': document.isEmpty ? null : document,
      };
}

/// `responseOutput` of `WeldInspection/GetDetails`.
class WeldData {
  /// True once a draft was saved (the web only offers Submit then).
  final bool hasDetails;
  final String pointNo;
  final List<WeldRow> rows;

  const WeldData({required this.hasDetails, required this.pointNo, required this.rows});

  factory WeldData.fromJson(Map<String, dynamic> j) {
    final details = j['inspectionDetails'];
    final point = details is Map ? (details['PointNo'] ?? details['pointNo'] ?? '') : '';
    return WeldData(
      hasDetails: details is Map,
      pointNo: point.toString(),
      rows: apiList(j['inspectionObservations']).map(WeldRow.fromJson).toList(),
    );
  }
}
