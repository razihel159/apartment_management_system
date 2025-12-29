import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TenantReportsListScreen extends StatefulWidget {
  final int tenantId;
  const TenantReportsListScreen({super.key, required this.tenantId});

  @override
  State<TenantReportsListScreen> createState() => _TenantReportsListScreenState();
}

class _TenantReportsListScreenState extends State<TenantReportsListScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      //Palitan ang localhost depende sa gamit mong device (10.0.2.2 o IP Address)
      final url = Uri.parse('http://localhost:3000/my-reports/${widget.tenantId}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            reports = jsonDecode(res.body)['data'];
            isLoading = false;
            errorMessage = "";
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to load reports";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection error";
        isLoading = false;
      });
      print("Error fetching reports: $e");
    }
  }

  // Helper para sa kulay ng status
  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'In Progress': return Colors.blue;
      case 'Resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            ElevatedButton(onPressed: fetchReports, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("No reports submitted yet.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reports.length,
        itemBuilder: (context, i) {
          final r = reports[i];
          
          // I-format ang date
          DateTime date = DateTime.parse(r['created_at']);
          String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: getStatusColor(r['status']).withOpacity(0.1),
                child: Icon(Icons.build_circle, color: getStatusColor(r['status'])),
              ),
              title: Text(
                r['issue_type'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(r['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(r['description']),
                      const SizedBox(height: 10),
                      if (r['image_url'] != null) ...[
                        const Text("Attachment:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'http://localhost:3000${r['image_url']}',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Text("Image could not be loaded", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}