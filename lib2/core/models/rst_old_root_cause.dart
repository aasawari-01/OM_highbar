class RstOldRootCause {
  final int? rootCauseId;
  final String? rootCause;
  final String? rootCauseText;

  RstOldRootCause({
    this.rootCauseId,
    this.rootCause,
    this.rootCauseText,
  });

  factory RstOldRootCause.fromJson(Map<String, dynamic> json) {
    return RstOldRootCause(
      rootCauseId: json['rootCauseId'] as int?,
      rootCause: json['rootCause']?.toString(),
      rootCauseText: json['rootCauseText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rootCauseId': rootCauseId,
    'rootCause': rootCause,
    'rootCauseText': rootCauseText,
  };
}
