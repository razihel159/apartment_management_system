enum MaintenanceStatus { pending, inProgress, completed }

class MaintenanceModel {
  final String id;
  final String tenantId;
  final String description;
  final String? imageUrl;
  final MaintenanceStatus status;
  final DateTime dateSubmitted;

  MaintenanceModel({
    required this.id,
    required this.tenantId,
    required this.description,
    this.imageUrl,
    this.status = MaintenanceStatus.pending,
    required this.dateSubmitted,
  });
}