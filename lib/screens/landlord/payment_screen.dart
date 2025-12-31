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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final pendingRes = await http.get(Uri.parse('http://localhost:3000/api/payments/list'));
      final historyRes = await http.get(Uri.parse('http://localhost:3000/api/payments/history'));
      
      if (pendingRes.statusCode == 200 && historyRes.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          pendingList = jsonDecode(pendingRes.body);
          historyList = jsonDecode(historyRes.body);
          isLoading = false;
        });
        // Debug para makita sa console ang actual keys
        print("DEBUG: Pending Data -> ${pendingRes.body}");
      }
    } catch (e) {
      print("Error fetching payments: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _processPayment(int tenantId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/payments/pay-rent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tenant_id': tenantId, 'amount': amount}),
      );
      if (response.statusCode == 200) {
        _showSuccess("Payment Received & Added to History!");
        fetchAllData();
      }
    } catch (e) { print(e); }
  }

  Future<void> _approveOnlinePayment(int paymentId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/payments/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payment_id': paymentId}),
      );
      if (response.statusCode == 200) {
        _showSuccess("Online Payment Approved!");
        fetchAllData();
      }
    } catch (e) { print(e); }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _viewProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Payment Proof"),
        content: SizedBox(
          width: 400,
          child: Image.network(
            "http://localhost:3000$imageUrl",
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                Text("Could not load image"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text("Rent Payments", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: "To Collect", icon: Icon(Icons.pending_actions)),
              Tab(text: "History", icon: Icon(Icons.history)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildTable(pendingList, isHistory: false),
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
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _headerCell("Tenant Name"),
                    _headerCell("Room"),
                    _headerCell("Amount"),
                    _headerCell(isHistory ? "Date Paid" : "Action"),
                  ],
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(3),
                  },
                  border: TableBorder(horizontalInside: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                  children: data.map((item) {
                    // MAPPING CHECK: Ginagamit 'fullname' o 'name'?
                    String displayName = item['fullname']?.toString() ?? item['name']?.toString() ?? 'N/A';
                    
                    // UPDATE: Dinagdagan ng item['monthly_rate'] 
                    String displayAmount = (item['paid_amount'] ?? item['monthly_rate'] ?? item['amount'] ?? item['rate'] ?? '0.00').toString();

                    bool hasProof = !isHistory && 
                                    (item['status'] == 'pending' || item['payment_status'] == 'pending') && 
                                    item['proof_image'] != null;

                    return TableRow(
                      children: [
                        _dataCell(displayName),
                        _dataCell("Room ${item['room_number'] ?? '?'}"),
                        _dataCell("₱$displayAmount"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: isHistory 
                            ? Text(item['payment_date']?.toString().split('T')[0] ?? 'N/A', style: const TextStyle(fontSize: 13))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (hasProof)
                                    ElevatedButton(
                                      onPressed: () => _viewProofImage(item['proof_image']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange, 
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: const Text("View", style: TextStyle(fontSize: 11)),
                                    ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (hasProof) {
                                        _approveOnlinePayment(item['payment_id'] ?? item['id']);
                                      } else {
                                        double amt = double.tryParse(displayAmount) ?? 0.0;
                                        _processPayment(item['tenant_id'] ?? item['id'], amt);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasProof ? Colors.blue : Colors.green, 
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: Text(hasProof ? "Approve" : "Receive", style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String txt) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _dataCell(String txt) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(txt, style: const TextStyle(fontSize: 13)),
    );
  }
}