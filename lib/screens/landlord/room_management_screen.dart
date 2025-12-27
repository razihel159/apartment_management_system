import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  List rooms = [];
  final _roomNumController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  // --- DATABASE FUNCTIONS ---

  Future<void> fetchRooms() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/rooms'));
      if (response.statusCode == 200) {
        setState(() => rooms = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching: $e");
    }
  }

  Future<void> _addRoom() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/add-room'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_number': _roomNumController.text,
          'rate': _rateController.text,
          'status': 'available',
        }),
      );
      if (response.statusCode == 200) {
        fetchRooms();
        _roomNumController.clear();
        _rateController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _deleteRoom(int id) async {
    try {
      final response = await http.delete(Uri.parse('http://localhost:3000/delete-room/$id'));
      if (response.statusCode == 200) fetchRooms();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _updateRoom(int id) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/update-room/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_number': _roomNumController.text,
          'rate': _rateController.text,
          'status': 'available',
        }),
      );
      if (response.statusCode == 200) {
        fetchRooms();
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  // --- UI DIALOGS ---

  void _showRoomDialog({Map? room}) {
    if (room != null) {
      _roomNumController.text = room['room_number'].toString();
      _rateController.text = room['rate'].toString();
    } else {
      _roomNumController.clear();
      _rateController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room == null ? "Add New Room" : "Edit Room"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _roomNumController, decoration: const InputDecoration(labelText: "Room Number")),
            TextField(controller: _rateController, decoration: const InputDecoration(labelText: "Monthly Rate"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => room == null ? _addRoom() : _updateRoom(room['id']),
            child: Text(room == null ? "Save" : "Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Room Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showRoomDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add New Room"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Table Section
        Expanded(
          child: Card(
            child: Container(
              width: double.infinity, // Pinapahaba nito ang card
              padding: const EdgeInsets.all(16),
              child: rooms.isEmpty
                  ? const Center(child: Text("No rooms found."))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 100, // Dinadagdagan ang distansya ng bawat column
                        columns: const [
                          DataColumn(label: Text('Room No.', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Monthly Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: rooms.map((room) => DataRow(cells: [
                          DataCell(Text(room['room_number'].toString())),
                          DataCell(Text("₱${room['rate']}")),
                          DataCell(_buildStatusBadge(room['status'])),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showRoomDialog(room: room),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRoom(room['id']),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'available' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}