enum PaymentStatus { paid, unpaid, overdue }

class PaymentModel {
  final String id;
  final String tenantId;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;

  PaymentModel({
    required this.id,
    required this.tenantId,
    required this.amount,
    required this.dueDate,
    this.status = PaymentStatus.unpaid,
  });
}