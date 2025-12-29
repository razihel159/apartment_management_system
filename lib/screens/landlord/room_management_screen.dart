import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Siguraduhin na tama ang path

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final ApiService _apiService = ApiService(); // Initialize Service
  List rooms = [];
  final _roomNumController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getRooms();
    setState(() {
      rooms = data;
      _isLoading = false;
    });
  }

  Future<void> _handleSave(int? id) async {
    final roomData = {
      'room_number': _roomNumController.text,
      'rate': _rateController.text,
      'status': 'available',
    };

    bool success;
    if (id == null) {
      success = await _apiService.addRoom(roomData);
    } else {
      success = await _apiService.updateRoom(id, roomData);
    }

    if (success) {
      fetchRooms();
      _roomNumController.clear();
      _rateController.clear();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed. Please try again.")),
        );
      }
    }
  }

  Future<void> _deleteRoom(int id) async {
    bool success = await _apiService.deleteRoom(id);
    if (success) {
      fetchRooms();
    }
  }

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
            onPressed: () => _handleSave(room?['id']),
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
        Expanded(
          child: Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : rooms.isEmpty
                  ? const Center(child: Text("No rooms found."))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 100, 
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