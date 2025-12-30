import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widgets/tenant_widgets.dart'; // Import ang bagong widgets

class TenantReportsListScreen extends StatefulWidget {
  final int tenantId;
  const TenantReportsListScreen({super.key, required this.tenantId});

  @override
  State<TenantReportsListScreen> createState() => _TenantReportsListScreenState();
}

class _TenantReportsListScreenState extends State<TenantReportsListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    setState(() => isLoading = true);
    final data = await _apiService.getTenantReports(widget.tenantId);
    if (mounted) {
      setState(() {
        reports = data;
        isLoading = false;
      });
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
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reports submitted yet."))
              : RefreshIndicator(
                  onRefresh: fetchReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: reports.length,
                    itemBuilder: (context, i) => ReportTile(report: reports[i]), // Galing sa tenant_widgets.dart
                  ),
                ),
    );
  }
}