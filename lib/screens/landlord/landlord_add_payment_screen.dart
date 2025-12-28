import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LandlordAddPaymentScreen extends StatefulWidget {
  const LandlordAddPaymentScreen({super.key});

  @override
  State<LandlordAddPaymentScreen> createState() => _LandlordAddPaymentScreenState();
}

class _LandlordAddPaymentScreenState extends State<LandlordAddPaymentScreen> {
  List<dynamic> tenants = [];
  String? selectedTenantId;
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTenants();
  }

  Future<void> fetchTenants() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/tenants'));
      if (res.statusCode == 200) {
        setState(() => tenants = jsonDecode(res.body));
      }
    } catch (e) {
      print("Error fetching tenants: $e");
    }
  }

  Future<void> submitPayment() async {
    if (selectedTenantId == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/pay-rent'),
        body: jsonEncode({
          'tenant_id': selectedTenantId,
          'amount': amountController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful!")));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Payment Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Process Rent Payment", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          width: 500, // Fixed width para magmukhang Web Form
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Payment Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              const Text("Select Tenant"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                value: selectedTenantId,
                items: tenants.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id'].toString(),
                    child: Text("${t['name']} - Room ${t['room_number']}"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedTenantId = val),
              ),
              
              const SizedBox(height: 20),
              const Text("Amount Paid"),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: "₱ ",
                  border: OutlineInputBorder(),
                  hintText: "0.00",
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitPayment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[900]),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Confirm Payment", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}