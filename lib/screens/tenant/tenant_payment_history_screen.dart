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

  Future<void> fetchPayments() async {
    try {
      // TANDAAN: Palitan ang localhost ng 10.0.2.2 kung gamit ay Android Emulator
      final url = Uri.parse('http://localhost:3000/my-payments/${widget.tenantId}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        setState(() {
          payments = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load payments";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
      print("Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("No payment records found.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: payments.length,
      itemBuilder: (context, i) {
        final p = payments[i];
        
        // Pag-format ng date (Halimbawa: Dec 27, 2025)
        DateTime date = DateTime.parse(p['payment_date']);
        String formattedDate = DateFormat('MMM dd, yyyy').format(date);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(
              "₱${double.parse(p['amount'].toString()).toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: $formattedDate"),
                Text("Status: ${p['status'].toString().toUpperCase()}", 
                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ),
        );
      },
    );
  }
}