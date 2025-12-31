import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/api_service.dart';

// --- 1. REUSABLE COMPONENTS (Small Units) ---

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const InfoCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
      ),
    );
  }
}

class EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool isObscure;

  const EditableField({super.key, required this.label, required this.controller, required this.icon, required this.enabled, this.isObscure = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: !enabled,
          fillColor: enabled ? Colors.transparent : Colors.grey[100],
        ),
      ),
    );
  }
}

class PaymentActionCard extends StatelessWidget {
  final VoidCallback onTap;
  const PaymentActionCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.indigo[50],
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.payments, color: Colors.white)),
        title: const Text("Ready to pay rent?"),
        subtitle: const Text("Click here to upload your receipt"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// --- 2. REPORT & STATUS COMPONENTS ---

class ReportStatusBadge extends StatelessWidget {
  final String status;
  const ReportStatusBadge({super.key, required this.status});

  Color _getStatusColor() {
    // Idinagdag ang 'Fixed' dahil ito ang nasa DB mo
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'In Progress': return Colors.blue;
      case 'Resolved': 
      case 'Fixed': return Colors.green; 
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const ReportTile({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Safety check para sa date nullability
    String formattedDate = "---";
    if (report['created_at'] != null) {
      DateTime date = DateTime.parse(report['created_at']);
      formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.build_circle, color: Colors.indigo),
        ),
        title: Text(report['issue_type'] ?? 'Issue', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12)),
        trailing: ReportStatusBadge(status: report['status'] ?? 'Pending'),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(report['description'] ?? 'No description provided.'),
                if (report['image_url'] != null) ...[
                  const SizedBox(height: 10),
                  const Text("Attachment:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${ApiService.baseUrl.replaceAll('/api', '')}${report['image_url']}',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Text("Image not available", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- 3. PAYMENT & PROOF COMPONENTS ---

class PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback? onTap;

  const PaymentTile({super.key, required this.payment, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Safety date check
    String formattedDate = "---";
    if (payment['payment_date'] != null) {
      DateTime date = DateTime.parse(payment['payment_date']);
      formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    }
    
    // to make sure ang key name na 'amount' (base sa DB)
    double amount = double.tryParse(payment['amount'].toString()) ?? 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
        title: Text(
          "₱${amount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date: $formattedDate", style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: payment['status'] == 'paid' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  (payment['status'] ?? 'PENDING').toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class ProofImageSelector extends StatelessWidget {
  final dynamic pickedFile;
  final VoidCallback onTap;

  const ProofImageSelector({super.key, required this.pickedFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: pickedFile == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  Text("Tap to select Receipt Screenshot"),
                ],
              )
            : kIsWeb 
                ? Image.network(pickedFile.path, fit: BoxFit.contain)
                : Image.file(File(pickedFile.path), fit: BoxFit.contain),
      ),
    );
  }
}

// --- 4. LARGE LAYOUT COMPONENTS (Full Views) ---

class TenantHomeView extends StatelessWidget {
  final String roomNumber;
  final String monthlyRate;
  final int unreadCount;
  final VoidCallback onUploadReceipt;
  final VoidCallback onFileReport;
  final VoidCallback onViewStatus;

  const TenantHomeView({
    super.key,
    required this.roomNumber,
    required this.monthlyRate,
    required this.unreadCount,
    required this.onUploadReceipt,
    required this.onFileReport,
    required this.onViewStatus,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InfoCard(title: "My Room", value: "Room $roomNumber", icon: Icons.apartment, color: Colors.blue),
          const SizedBox(height: 10),
          InfoCard(title: "Monthly Rent", value: "₱$monthlyRate", icon: Icons.payments, color: Colors.green),
          const SizedBox(height: 15),
          PaymentActionCard(onTap: onUploadReceipt),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onFileReport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900], padding: const EdgeInsets.symmetric(vertical: 15)),
                  icon: const Icon(Icons.report_problem, color: Colors.white),
                  label: const Text("File Report", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onViewStatus,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.indigo)),
                        icon: const Icon(Icons.list_alt, color: Colors.indigo),
                        label: const Text("View Status"),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}