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

  // UPDATED: Path changed to match server.js (/api/reports/all)
  Future<void> fetchReports() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/reports/all'));
      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching reports: $e");
      setState(() => isLoading = false);
    }
  }

  // UPDATED: Path changed to match server.js (/api/reports/update-status)
  Future<void> updateStatus(int reportId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/reports/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'report_id': reportId, 'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report marked as $newStatus"), backgroundColor: Colors.green),
        );
        fetchReports(); // Refresh the list automatically
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TENANT REPORTS", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(onPressed: fetchReports, icon: const Icon(Icons.refresh, color: Colors.white))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reports yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    
                    // Safe date parsing
                    String formattedDate = "N/A";
                    if (report['created_at'] != null) {
                      DateTime date = DateTime.parse(report['created_at']);
                      formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(report['status']),
                          child: const Icon(Icons.report_problem, color: Colors.white),
                        ),
                        title: Text(
                          "${report['issue_type']} - Room ${report['room_number'] ?? 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("From: ${report['tenant_name'] ?? 'Unknown'}\n$formattedDate"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(report['description'] ?? "No description provided."),
                                const SizedBox(height: 15),
                                
                                // Image display (Optional, only shows if image exists)
                                if (report['image_url'] != null) ...[
                                  const Text("Attached Image:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Image.network(
                                    "http://localhost:3000${report['image_url']}",
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text("Image not available"),
                                  ),
                                  const SizedBox(height: 15),
                                ],

                                const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(status),
    );
  }

  Color _getStatusColor(dynamic status) {
    String s = status?.toString() ?? 'Pending';
    if (s == 'Pending') return Colors.orange;
    if (s == 'In Progress') return Colors.blue;
    if (s == 'Fixed') return Colors.green;
    return Colors.grey;
  }
}