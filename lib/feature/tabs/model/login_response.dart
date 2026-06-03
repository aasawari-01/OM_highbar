class LoginResponse {
  final bool status;
  final String? message;
  final LoginData? data;
  final int? totalRecords;

  LoginResponse({
    required this.status,
    this.message,
    this.data,
    this.totalRecords,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : LoginData.fromJson(json['data'] as Map<String, dynamic>),
      totalRecords: json['totalRecords'] as int?,
    );
  }
}

class LoginData {
  final int? id;
  final String? emailID;
  final String? firstName;
  final String? lastName;
  final Role? role;
  final List<City> cities;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  LoginData({
    this.id,
    this.emailID,
    this.firstName,
    this.lastName,
    this.role,
    this.cities = const [],
    this.accessToken,
    this.refreshToken,
    this.tokenType,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'] as int?,
      emailID: json['emailID'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      role: json['role'] == null
          ? null
          : Role.fromJson(json['role'] as Map<String, dynamic>),
      cities: (json['cities'] as List<dynamic>?)
              ?.map((e) => City.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String?,
    );
  }
}

class Role {
  final int? id;
  final String? name;

  Role({
    this.id,
    this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }
}

class City {
  final int? id;
  final String? name;

  City({
    this.id,
    this.name,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }
}

