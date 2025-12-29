import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RentMonitoringScreen extends StatefulWidget {
  const RentMonitoringScreen({super.key});

  @override
  State<RentMonitoringScreen> createState() => _RentMonitoringScreenState();
}

class _RentMonitoringScreenState extends State<RentMonitoringScreen> {
  List<dynamic> balances = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBalances();
  }

  // UPDATED: URL reflects the /api/payments/overdue endpoint
  Future<void> fetchBalances() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/payments/overdue'));
      if (res.statusCode == 200) {
        setState(() {
          balances = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching balances: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rent Monitoring", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: fetchBalances,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : balances.isEmpty
              ? const Center(child: Text("All tenants are up to date!"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text("Tenant", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Room", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Amount Due", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: balances.map((data) {
                        // Safe parsing
                        double balanceValue = double.tryParse(data['balance'].toString()) ?? 0.0;
                        
                        return DataRow(cells: [
                          DataCell(Text(data['name'] ?? 'N/A')),
                          DataCell(Text(data['room_number']?.toString() ?? 'N/A')),
                          DataCell(Text("₱${balanceValue.toStringAsFixed(2)}", 
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: const Text(
                                "OVERDUE", 
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            )
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}