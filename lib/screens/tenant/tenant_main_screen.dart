import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'report_issue_screen.dart';
import 'tenant_reports_list_screen.dart';
import 'tenant_payment_history_screen.dart'; 
// SIGURADUHIN NA TAMA ANG FILE NAME NG UPLOAD PROOF SCREEN MO DITO:
import 'tenant_upload_proof_screen.dart'; 
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

  bool isEditing = false;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchNotifications();
    _emailController = TextEditingController(text: widget.userData['email']);
    _contactController = TextEditingController(text: widget.userData['contact']);
    _passwordController = TextEditingController(text: widget.userData['password']);
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

  Future<void> _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/update-tenant-profile/${widget.userData['id']}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'contact': _contactController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        setState(() => isEditing = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        onTap: (i) => setState(() {
           _selectedIndex = i;
           isEditing = false;
        }),
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
          
          const SizedBox(height: 15),

          // --- DAGDAG: PAY RENT BUTTON ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.indigo[50],
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.payments, color: Colors.white),
              ),
              title: const Text("Ready to pay rent?"),
              subtitle: const Text("Click here to upload your receipt"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TenantUploadProofScreen(
                      tenantId: widget.userData['id'].toString(),
                      tenantName: tenantName,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen(tenantId: widget.userData['id']))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[900], 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: const Icon(Icons.report_problem, color: Colors.white),
                  label: const Text("File Report", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => unreadCount = 0); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TenantReportsListScreen(tenantId: widget.userData['id'])));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.indigo),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        icon: const Icon(Icons.list_alt, color: Colors.indigo),
                        label: const Text("View Status"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Colors.indigo, child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 10),
          Text(tenantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Tenant Member", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          _buildEditableField("Email Address", _emailController, Icons.email, isEditing),
          _buildEditableField("Contact Number", _contactController, Icons.phone, isEditing),
          _buildEditableField("Password", _passwordController, Icons.lock, isEditing, isObscure: true),
          
          const SizedBox(height: 20),
          
          if (!isEditing)
            ElevatedButton.icon(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => isEditing = false),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()), 
              (r) => false
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController ctrl, IconData icon, bool enabled, {bool isObscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: !enabled,
          fillColor: enabled ? Colors.transparent : Colors.grey[100],
        ),
      ),
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