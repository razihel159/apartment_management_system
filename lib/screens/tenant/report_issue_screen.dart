import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Siguraduhin ang tamang path sa file mo

class ReportIssueScreen extends StatefulWidget {
  final int tenantId;
  const ReportIssueScreen({super.key, required this.tenantId});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _descController = TextEditingController();
  String _selectedType = 'Plumbing';

  // Ang pinalitan lang natin ay ang loob nito para kumonekta sa ApiService
  Future<void> _submitReport() async {
    final success = await ApiService().submitReport({
      'tenant_id': widget.tenantId,
      'issue_type': _selectedType,
      'description': _descController.text,
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Sent!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send report.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report an Issue"), backgroundColor: Colors.indigo[900]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedType, // pinalitan ko lang ng 'value' (hindi initialValue) para gumana ang update
              items: ['Plumbing', 'Electrical', 'Maintenance', 'Noise', 'Others']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedType = val as String),
              decoration: const InputDecoration(labelText: "Issue Type", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900], minimumSize: const Size(double.infinity, 50)),
              child: const Text("Submit Report", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}