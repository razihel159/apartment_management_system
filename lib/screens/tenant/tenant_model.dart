class TenantModel {
  final String id;
  final String name;
  final String contact;
  final String email; // Dagdag para sa profile
  final String assignedRoom; 
  final String monthlyRate; // Dagdag para sa dashboard
  final DateTime startDate;

  TenantModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    required this.assignedRoom,
    required this.monthlyRate,
    required this.startDate,
  });

  // Mahalaga ito para ma-convert ang JSON mula sa Node.js papuntang Flutter object
  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      assignedRoom: json['room_number'] ?? '---', // Sync sa backend column
      monthlyRate: json['rate']?.toString() ?? '0.00', // Sync sa backend column
      startDate: json['date_started'] != null 
          ? DateTime.parse(json['date_started']) 
          : DateTime.now(),
    );
  }
}