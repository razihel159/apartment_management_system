import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List pendingList = [];
  List historyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final pendingRes = await http.get(Uri.parse('http://localhost:3000/payment-list'));
      final historyRes = await http.get(Uri.parse('http://localhost:3000/payment-history'));
      
      if (pendingRes.statusCode == 200 && historyRes.statusCode == 200) {
        setState(() {
          pendingList = jsonDecode(pendingRes.body);
          historyList = jsonDecode(historyRes.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _processPayment(int tenantId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/pay-rent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tenant_id': tenantId, 'amount': amount}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Received & Added to History!")),
        );
        fetchAllData(); // Refresh both lists
      }
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rent Payments", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: "Pending (To Collect)", icon: Icon(Icons.pending_actions)),
              Tab(text: "History (Paid Records)", icon: Icon(Icons.history)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // TAB 1: PENDING
                    _buildTable(pendingList, isHistory: false),
                    // TAB 2: HISTORY
                    _buildTable(historyList, isHistory: true),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List data, {required bool isHistory}) {
    if (data.isEmpty) {
      return Center(
        child: Text(isHistory ? "No payment history yet." : "All tenants have paid for this month!"),
      );
    }
    
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Tenant Name')),
            const DataColumn(label: Text('Room')),
            const DataColumn(label: Text('Amount')),
            DataColumn(label: Text(isHistory ? 'Date Paid' : 'Action')),
          ],
          rows: data.map((item) => DataRow(cells: [
            DataCell(Text(item['fullname'])),
            DataCell(Text("Room ${item['room_number']}")),
            DataCell(Text("₱${item['amount'] ?? item['monthly_rate']}")),
            DataCell(isHistory 
              ? Text(item['payment_date'].toString().split('T')[0]) 
              : ElevatedButton(
                  onPressed: () => _processPayment(item['tenant_id'], double.parse(item['monthly_rate'].toString())),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Receive"),
                )),
          ])).toList(),
        ),
      ),
    );
  }
}