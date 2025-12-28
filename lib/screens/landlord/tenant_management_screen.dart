import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  List tenants = [];
  List availableRooms = []; // Listahan para sa dropdown
  bool isLoading = true;

  // Controllers para sa Form
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  int? selectedRoomId;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchRooms();
  }

  // --- DATABASE FUNCTIONS ---

  Future<void> fetchData() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/tenants'));
      if (res.statusCode == 200) {
        setState(() {
          tenants = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchRooms() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/rooms'));
      if (res.statusCode == 200) {
        List allRooms = jsonDecode(res.body);
        setState(() {
          // Kunin lang ang mga rooms na 'available'
          availableRooms = allRooms.where((r) => r['status'] == 'available').toList();
        });
      }
    } catch (e) { print(e); }
  }

  Future<void> _addTenant() async {
    if (selectedRoomId == null) return;

    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/add-tenant'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'room_id': selectedRoomId,
        }),
      );

      if (res.statusCode == 200) {
        fetchData(); // Refresh list
        fetchRooms(); // Update available rooms
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tenant Added Successfully!")));
        
        // Clear inputs
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        selectedRoomId = null;
      }
    } catch (e) { print(e); }
  }

  // --- UI DIALOG ---

  void _showAddTenantDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Kailangan ito para mag-update ang dropdown sa loob ng dialog
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Tenant"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email Address")),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    initialValue: selectedRoomId,
                    hint: const Text("Select Room"),
                    items: availableRooms.map((room) {
                      return DropdownMenuItem<int>(
                        value: room['id'],
                        child: Text("Room ${room['room_number']} (₱${room['rate']})"),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedRoomId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(onPressed: _addTenant, child: const Text("Save Tenant")),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tenant Management",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showAddTenantDialog, // TINAWAG NA YUNG DIALOG DITO
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Tenant"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 150),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Room')),
                                  DataColumn(label: Text('Contact')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: tenants.map((t) => DataRow(cells: [
                                  DataCell(Text(t['name']?.toString() ?? "N/A")),
                                  DataCell(Text("Room ${t['room_number']?.toString() ?? 'N/A'}")),
                                  DataCell(Text(t['contact']?.toString() ?? "N/A")),
                                  DataCell(const Icon(Icons.delete, color: Colors.redAccent, size: 18)),
                                ])).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}