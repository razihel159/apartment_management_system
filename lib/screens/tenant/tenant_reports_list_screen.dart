import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantReportsListScreen extends StatefulWidget {
  final int tenantId;
  const TenantReportsListScreen({super.key, required this.tenantId});

  @override
  State<TenantReportsListScreen> createState() => _TenantReportsListScreenState();
}

class _TenantReportsListScreenState extends State<TenantReportsListScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final res = await http.get(Uri.parse('http://localhost:3000/my-reports/${widget.tenantId}'));
    if (res.statusCode == 200) {
      setState(() {
        reports = jsonDecode(res.body)['data'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Reports"), backgroundColor: Colors.indigo[900]),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, i) {
          final r = reports[i];
          return Card(
            child: ListTile(
              title: Text(r['issue_type'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r['description']),
              trailing: Chip(
                label: Text(r['status'], style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: r['status'] == 'Pending' ? Colors.orange : r['status'] == 'In Progress' ? Colors.blue : Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}