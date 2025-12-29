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
  List vacantRooms = [];
  bool isLoading = true;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedRoomId;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() {
    fetchTenants();
    fetchVacantRooms();
  }

  Future<void> fetchTenants() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/tenants'));
      if (response.statusCode == 200) {
        setState(() {
          tenants = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error tenants: $e");
    }
  }

  Future<void> fetchVacantRooms() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/rooms/available'));
      if (response.statusCode == 200) {
        setState(() {
          vacantRooms = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error rooms: $e");
    }
  }

  Future<void> registerTenant() async {
    if (selectedRoomId == null || nameController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/tenants/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "contact": contactController.text,
          "email": emailController.text,
          "password": passwordController.text.isEmpty ? "password123" : passwordController.text,
          "room_id": selectedRoomId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        fetchData();
        nameController.clear();
        contactController.clear();
        emailController.clear();
        passwordController.clear();
        selectedRoomId = null;
      }
    } catch (e) {
      print(e);
    }
  }

  void _showAddTenantDialog() {
    fetchVacantRooms(); // Fresh data bago mag-dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Register New Tenant", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name")),
                  TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact No")),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedRoomId,
                    hint: const Text("Select Vacant Room"),
                    items: vacantRooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room['id'].toString(),
                        child: Text("Room ${room['room_number']} - ₱${room['rate']}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedRoomId = val;
                      });
                    },
                  ),
                  if (vacantRooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("No vacant rooms available", style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: vacantRooms.isEmpty ? null : registerTenant,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text("Register"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTenantDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tenant Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(1.2),
                        },
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[200]),
                            children: [_headerCell("Name"), _headerCell("Room"), _headerCell("Contact"), _headerCell("Action")],
                          ),
                          ...tenants.map((tenant) => TableRow(
                            children: [
                              _dataCell(tenant['name']),
                              _dataCell("R-${tenant['room_number']}"),
                              _dataCell(tenant['contact']),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => deleteTenant(tenant['id']),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String txt) => Padding(padding: const EdgeInsets.all(12), child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget _dataCell(String txt) => Padding(padding: const EdgeInsets.all(12), child: Text(txt.toString()));

  Future<void> deleteTenant(int id) async {
    await http.delete(Uri.parse('http://localhost:3000/api/tenants/delete/$id'));
    fetchData();
  }
}