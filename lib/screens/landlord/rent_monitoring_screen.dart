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
    final res = await http.get(Uri.parse('http://localhost:3000/tenant-balances'));
    if (res.statusCode == 200) {
      setState(() {
        balances = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rent Monitoring"), backgroundColor: Colors.indigo),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Tenant")),
                  DataColumn(label: Text("Room")),
                  DataColumn(label: Text("Balance")),
                  DataColumn(label: Text("Status")),
                ],
                rows: balances.map((data) => DataRow(cells: [
                  DataCell(Text(data['name'])),
                  DataCell(Text(data['room_number'].toString())),
                  DataCell(Text("₱${data['balance']}", style: TextStyle(color: data['balance'] > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: data['status'] == "Overdue" ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text(data['status'], style: TextStyle(color: data['status'] == "Overdue" ? Colors.red : Colors.green)),
                    )
                  ),
                ])).toList(),
              ),
            ),
    );
  }
}