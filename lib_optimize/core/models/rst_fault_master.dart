class RstFaultMaster {
  final int? faultId;
  final String? fault;
  final String? faultText;

  RstFaultMaster({
    this.faultId,
    this.fault,
    this.faultText,
  });

  factory RstFaultMaster.fromJson(Map<String, dynamic> json) {
    return RstFaultMaster(
      faultId: json['faultId'] as int?,
      fault: json['fault']?.toString(),
      faultText: json['faultText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'faultId': faultId,
    'fault': fault,
    'faultText': faultText,
  };
}
