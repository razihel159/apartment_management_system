class TenantModel {
  final String id;
  final String name;
  final String contact;
  final String assignedRoomId;
  final DateTime startDate;

  TenantModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.assignedRoomId,
    required this.startDate,
  });
}