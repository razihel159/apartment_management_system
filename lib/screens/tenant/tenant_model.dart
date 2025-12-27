class TenantModel {
  final String id;
  final String name;
  final String contact;
  final String assignedRoom; // Room Number
  final DateTime startDate;

  TenantModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.assignedRoom,
    required this.startDate,
  });
}