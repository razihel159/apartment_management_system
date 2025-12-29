import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// MGA IMPORTS
import 'landlord_add_payment_screen.dart';
import 'room_management_screen.dart';
import 'tenant_management_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';
import 'landlord_reports_screen.dart'; 
import 'rent_monitoring_screen.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> stats = {
    "totalRooms": "0", 
    "occupiedRooms": "0", 
    "vacantRooms": "0", 
    "totalCollected": "0",
    "overdueTenants": "0" 
  };

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  // UPDATED: Path updated to /api/rooms/dashboard-stats to match backend routes
  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/rooms/dashboard-stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stats = {
            "totalRooms": data['totalRooms']?.toString() ?? "0",
            "occupiedRooms": data['occupiedRooms']?.toString() ?? "0",
            "vacantRooms": data['vacantRooms']?.toString() ?? "0",
            "totalCollected": data['totalCollected']?.toString() ?? "0",
            "overdueTenants": data['overdueTenants']?.toString() ?? "0",
          };
        });
      }
    } catch (e) { 
      print("Error fetching stats: $e"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listahan ng mga pages
    final List<Widget> pages = [
      _buildDashboardOverview(), 
      const RoomManagementScreen(),
      const TenantManagementScreen(),
      const PaymentScreen(),
      const LandlordReportsScreen(), 
      const SettingsScreen(),          
    ];

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR SECTION
          Container(
            width: 260,
            color: Colors.indigo[900],
            child: Column(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text(
                      "APARTMENT ADMIN", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                    )
                  )
                ),
                _sidebarTile(Icons.dashboard, "Dashboard Overview", 0),
                _sidebarTile(Icons.door_front_door, "Room Management", 1),
                _sidebarTile(Icons.people, "Tenant Management", 2),
                _sidebarTile(Icons.payment, "Rent Payments", 3),
                _sidebarTile(Icons.report_problem, "Tenant Reports", 4), 
                _sidebarTile(Icons.settings, "Settings", 5),                
              ],
            ),
          ),
          // MAIN CONTENT SECTION
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(32),
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dashboard Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(onPressed: fetchStats, icon: const Icon(Icons.refresh, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _buildStatCard("Total Rooms", stats['totalRooms'], Icons.door_front_door, Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard("Occupied", stats['occupiedRooms'], Icons.person_pin, Colors.green),
              const SizedBox(width: 20),
              _buildStatCard("Vacant", stats['vacantRooms'], Icons.event_available, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard("Collected Rent", "₱${stats['totalCollected']}", Icons.payments, Colors.teal),
              const SizedBox(width: 20),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Refresh stats pagbalik galing monitoring
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RentMonitoringScreen()))
                             .then((_) => fetchStats());
                  },
                  child: _buildStatCardUI("Overdue Tenants", stats['overdueTenants'], Icons.notification_important, Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _actionButton("Add Room", Icons.add, () {
                setState(() => _selectedIndex = 1);
                fetchStats(); 
              }),
              _actionButton("Register Tenant", Icons.person_add, () {
                setState(() => _selectedIndex = 2);
                fetchStats();
              }),
              _actionButton("Process Payment", Icons.payment, () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const LandlordAddPaymentScreen())
                ).then((_) => fetchStats()); 
              }),
              _actionButton("View Reports", Icons.warning_amber, () => setState(() => _selectedIndex = 4)),
            ],
          )
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStatCardUI(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(8), 
          border: Border(left: BorderSide(color: color, width: 6))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(child: _buildStatCardUI(title, value, icon, color));
  }

  Widget _sidebarTile(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white54),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        fetchStats(); 
      },
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        backgroundColor: Colors.white,
        foregroundColor: Colors.purple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
          side: BorderSide(color: Colors.purple.withOpacity(0.2))
        )
      ),
    );
  }
}