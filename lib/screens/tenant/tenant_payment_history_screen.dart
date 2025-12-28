import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  // Ginawang function para pwedeng tawagin ng RefreshIndicator
  Future<void> fetchPayments() async {
    try {
      // TANDAAN: Gamitin ang 10.0.2.2 para sa Android Emulator o IP Address para sa Real Device
      final url = Uri.parse('http://localhost:3000/my-payments/${widget.tenantId}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            payments = data['data'];
            isLoading = false;
            errorMessage = "";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "Failed to load payments";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error connecting to server";
          isLoading = false;
        });
      }
      print("Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Inalis ang AppBar dito dahil tinatawag ito sa loob ng PageView/Index ng Main Screen
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
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => isLoading = true);
                fetchPayments();
              },
              child: const Text("Retry"),
            )
          ],
        ),
      );
    }

    if (payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchPayments,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No payment records found.", style: TextStyle(color: Colors.grey)),
                  Text("Swipe down to refresh", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchPayments,
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: payments.length,
        itemBuilder: (context, i) {
          final p = payments[i];
          
          // Formatting ng Petsa
          DateTime date = DateTime.parse(p['payment_date']);
          String formattedDate = DateFormat('MMMM dd, yyyy').format(date);

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
                "₱${double.parse(p['amount'].toString()).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  color: Colors.black87
                ),
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
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        p['status'].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Pwedeng lagyan dito ng "Show Receipt Details" dialog sa future
              },
            ),
          );
        },
      ),
    );
  }
}