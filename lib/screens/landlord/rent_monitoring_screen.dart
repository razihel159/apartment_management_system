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

  Future<void> fetchBalances() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/tenant-balances'));
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
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
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
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(label: Text("Tenant", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Room", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Balance", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: balances.map((data) {
                    // Safe parsing ng balance
                    double balanceValue = double.tryParse(data['balance'].toString()) ?? 0.0;
                    bool isOverdue = data['status'] == "Overdue";

                    return DataRow(cells: [
                      DataCell(Text(data['name'] ?? 'N/A')),
                      DataCell(Text(data['room_number']?.toString() ?? 'N/A')),
                      DataCell(Text("₱${balanceValue.toStringAsFixed(2)}", 
                          style: TextStyle(color: balanceValue > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            data['status'] ?? 'N/A', 
                            style: TextStyle(color: isOverdue ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
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