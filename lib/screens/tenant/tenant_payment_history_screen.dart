import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widgets/tenant_widgets.dart';

class TenantPaymentHistoryScreen extends StatefulWidget {
  final int tenantId;
  const TenantPaymentHistoryScreen({super.key, required this.tenantId});

  @override
  State<TenantPaymentHistoryScreen> createState() => _TenantPaymentHistoryScreenState();
}

class _TenantPaymentHistoryScreenState extends State<TenantPaymentHistoryScreen> {
  List<dynamic> payments = [];
  bool isLoading = true;
  String errorMessage = "";
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    setState(() => isLoading = true);
    try {
      // Gagamit ng centralized ApiService
      final data = await _apiService.getTenantPaymentHistory(widget.tenantId);
      
      if (mounted) {
        setState(() {
          payments = data;
          isLoading = false;
          errorMessage = data.isEmpty ? "" : ""; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error connecting to server";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            Text(errorMessage),
            ElevatedButton(onPressed: fetchPayments, child: const Text("Retry"))
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPayments,
      child: payments.isEmpty 
        ? _buildEmptyState() 
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: payments.length,
            itemBuilder: (context, i) => PaymentTile(payment: payments[i]),
          ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 60, color: Colors.grey),
              Text("No payment records found.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}