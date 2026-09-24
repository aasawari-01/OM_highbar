class NotificationTypeModel {
  final int? id;
  final String notificationType;
  final String? description;
  final String? createdOn;
  final String? updatedOn;

  NotificationTypeModel({
    this.id,
    required this.notificationType,
    this.description,
    this.createdOn,
    this.updatedOn,
  });

  factory NotificationTypeModel.fromJson(Map<String, dynamic> json) {
    return NotificationTypeModel(
      id: json['Id'] as int? ?? json['id'] as int?,
      notificationType: json['NotificationType']?.toString() ?? json['notificationType']?.toString() ?? '',
      description: json['Description']?.toString() ?? json['description']?.toString(),
      createdOn: json['CreatedOn']?.toString() ?? json['createdOn']?.toString(),
      updatedOn: json['UpdatedOn']?.toString() ?? json['updatedOn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notificationType': notificationType,
    'description': description,
    'createdOn': createdOn,
    'updatedOn': updatedOn,
  };
}
