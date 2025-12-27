import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'report_issue_screen.dart';
import 'tenant_reports_list_screen.dart';
import 'tenant_payment_history_screen.dart'; // Import sa history screen
import '../login_screen.dart';

class TenantMainScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TenantMainScreen({super.key, required this.userData});

  @override
  State<TenantMainScreen> createState() => _TenantMainScreenState();
}

class _TenantMainScreenState extends State<TenantMainScreen> {
  int _selectedIndex = 0;
  String tenantName = "";
  String roomNumber = "---";
  String monthlyRate = "0.00";
  int unreadCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/unread-reports-count/${widget.userData['id']}'));
      if (res.statusCode == 200) {
        setState(() => unreadCount = jsonDecode(res.body)['count']);
      }
    } catch (e) { print(e); }
  }

  Future<void> fetchData() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/tenant-details/${widget.userData['id']}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        setState(() {
          tenantName = data['name'];
          roomNumber = data['room_number'];
          monthlyRate = data['rate'].toString();
          isLoading = false;
        });
      }
    } catch (e) { 
      print("Error fetching data: $e");
      setState(() => isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // DITO ANG PAGBABAGO: Pinalitan ang Text("History") ng TenantPaymentHistoryScreen
    final List<Widget> pages = [
      _buildHome(), 
      TenantPaymentHistoryScreen(tenantId: widget.userData['id']), 
      _buildProfile()
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("TENANT PORTAL"), 
        backgroundColor: Colors.indigo[900],
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Text(tenantName, style: const TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.indigo[900],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard("Room $roomNumber", "₱$monthlyRate", Icons.apartment, Colors.blue),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen(tenantId: widget.userData['id']))),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900]),
                  child: const Text("File Report", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => unreadCount = 0); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TenantReportsListScreen(tenantId: widget.userData['id'])));
                        },
                        child: const Text("View Status"),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -5, top: -5,
                        child: CircleAvatar(
                          radius: 10, backgroundColor: Colors.red,
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 10),
        Text(tenantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout"),
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()), 
            (r) => false
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String t, String v, IconData i, Color c) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(i, color: c, size: 40), 
        title: Text(t), 
        subtitle: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black))
      )
    );
  }
}