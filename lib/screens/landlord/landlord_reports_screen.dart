import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class LandlordReportsScreen extends StatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  State<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends State<LandlordReportsScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/all-reports'));
      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(int reportId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/update-report-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'report_id': reportId, 'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Report marked as $newStatus")));
        fetchReports(); // Refresh the list
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TENANT REPORTS"), backgroundColor: Colors.indigo),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reports yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    DateTime date = DateTime.parse(report['created_at']);
                    String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(report['status']),
                          child: const Icon(Icons.report_problem, color: Colors.white),
                        ),
                        title: Text("${report['issue_type']} - Room ${report['room_number']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("From: ${report['tenant_name']}\n$formattedDate"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(report['description'] ?? "No description"),
                                const SizedBox(height: 15),
                                const Text("Actions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _actionBtn(report['id'], "In Progress", Colors.blue),
                                    const SizedBox(width: 10),
                                    _actionBtn(report['id'], "Fixed", Colors.green),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _actionBtn(int id, String status, Color color) {
    return ElevatedButton(
      onPressed: () => updateStatus(id, status),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      child: Text(status),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Pending') return Colors.orange;
    if (status == 'In Progress') return Colors.blue;
    return Colors.green;
  }
}