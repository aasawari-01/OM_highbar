/// Field names under which GetAllFailuresTransactionData can carry the
/// encrypted failure id (the web list's jobCardNo) inside a siFailure.
const List<String> kSiEncryptedIdKeys = [
  'jobCardNo',
  'JobCardNo',
  'encryptedId',
  'encryptedNotificationId',
  'notificationEncryptId',
  'jobCardId',
];

/// The encrypted id in [si] (a siFailure map), or null when the sync does not
/// carry one. A plain copy of the numeric [notificationId] does not count.
String? encryptedIdFromSiFailure(Map<dynamic, dynamic> si, int notificationId) {
  for (final key in kSiEncryptedIdKeys) {
    final v = si[key]?.toString().trim() ?? '';
    if (v.isNotEmpty && v != notificationId.toString()) return v;
  }
  return null;
}
