/// One option of a `{value, label}` drop-down.
class SelectOption {
  final String value;
  final String label;

  const SelectOption(this.value, this.label);

  factory SelectOption.fromJson(Map<String, dynamic> j) =>
      SelectOption((j['value'] ?? '').toString(), (j['label'] ?? '').toString());
}

/// The API sends lists either as a list or as an index-keyed map; always returns the maps.
List<Map<String, dynamic>> apiList(dynamic v) {
  final items = v is Map ? v.values : (v is List ? v : const []);
  return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

/// Drop-down options from an API list.
List<SelectOption> apiOptions(dynamic v) => apiList(v).map(SelectOption.fromJson).toList();

/// Ids go over the wire as numbers (as the web sends them) when they parse as one.
dynamic wireId(String id) => int.tryParse(id) ?? id;
