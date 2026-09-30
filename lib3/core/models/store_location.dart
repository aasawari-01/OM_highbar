class StoreLocation {
  final int? storeLocationId;
  final String? storeLocation;
  final String? storeLocationDesc;

  StoreLocation({
    this.storeLocationId,
    this.storeLocation,
    this.storeLocationDesc,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    // Handle database schema (StoreId, StoreDetails columns)
    int? id;
    String? location;
    String? desc;
    
    if (json['StoreId'] != null) {
      id = json['StoreId'] as int?;
      location = json['StoreDetails']?.toString();
      desc = json['StoreDetails']?.toString();
    } else {
      id = json['storeLocationId'] as int?;
      location = json['storeLocation']?.toString();
      desc = json['storeLocationDesc']?.toString();
    }
    
    return StoreLocation(
      storeLocationId: id,
      storeLocation: location,
      storeLocationDesc: desc,
    );
  }

  Map<String, dynamic> toJson() => {
    'storeLocationId': storeLocationId,
    'storeLocation': storeLocation,
    'storeLocationDesc': storeLocationDesc,
  };
}
