import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widgets/tenant_widgets.dart'; 
import 'report_issue_screen.dart';
import 'tenant_reports_list_screen.dart';
import 'tenant_payment_history_screen.dart';
import 'tenant_upload_proof_screen.dart';
import '../login_screen.dart';
import 'dart:convert'; 
import 'package:http/http.dart' as http; 

class TenantMainScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TenantMainScreen({super.key, required this.userData});

  @override
  State<TenantMainScreen> createState() => _TenantMainScreenState();
}

class _TenantMainScreenState extends State<TenantMainScreen> {
  int _selectedIndex = 0;
  String tenantName = "", roomNumber = "---", monthlyRate = "0.00";
  int unreadCount = 0;
  bool isLoading = true, isEditing = false;

  final ApiService _apiService = ApiService();
  
  // MGA CONTROLLERS PARA SA PROFILE EDIT
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  late TextEditingController _passwordController; // Para sa password update

  @override
  void initState() {
    super.initState();
    // Debug print para ma-verify kung anong ID ang gamit sa login
    print("DEBUG: Logged in Tenant ID -> ${widget.userData['id']}");
    
    tenantName = widget.userData['name'] ?? "Tenant";
    _emailController = TextEditingController(text: widget.userData['email']);
    _contactController = TextEditingController(text: widget.userData['contact']?.toString() ?? "");
    _passwordController = TextEditingController(); // Laging empty sa simula para sa security
    
    fetchData();
  }

  // Pinanatili ang iyong orihinal na fetchData logic
  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final int tenantId = widget.userData['id'];
      
      // 1. Kunin ang Profile Data
      final profileData = await _apiService.getTenantProfile(tenantId);
      
      // 2. Kunin ang Room Stats (Room Number at Monthly Rent)
      final response = await http.get(Uri.parse('http://localhost:3000/api/payments/stats/$tenantId'));

      if (mounted) {
        setState(() {
          if (profileData != null) {
            tenantName = profileData['name'] ?? widget.userData['name'];
            // I-sync ang controllers sa latest data mula DB
            _emailController.text = profileData['email'] ?? _emailController.text;
            _contactController.text = profileData['contact']?.toString() ?? _contactController.text;
          }

          if (response.statusCode == 200) {
            final stats = jsonDecode(response.body);
            roomNumber = stats['room_number']?.toString() ?? '---';
            monthlyRate = stats['monthly_rent']?.toString() ?? '0.00';
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      print("DEBUG: Fetch Error -> $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // BAGONG FUNCTION: Para i-save ang binagong Profile at Password
  Future<void> _handleSaveProfile() async {
    setState(() => isLoading = true);
    
    final Map<String, dynamic> updateData = {
      'email': _emailController.text,
      'contact': _contactController.text,
    };

    // Isasama lang ang password field kung may tinype si tenant
    if (_passwordController.text.isNotEmpty) {
      updateData['password'] = _passwordController.text;
    }

    final bool success = await _apiService.updateTenantProfile(
      widget.userData['id'], 
      updateData
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        isEditing = false;
        _passwordController.clear(); // Clear ang password field pagkatapos i-save
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Profile updated successfully!" : "Failed to update profile"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) fetchData(); // I-refresh ang data para updated ang UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TenantHomeView(
        roomNumber: roomNumber,
        monthlyRate: monthlyRate,
        unreadCount: unreadCount,
        onUploadReceipt: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TenantUploadProofScreen(tenantId: widget.userData['id'].toString(), tenantName: tenantName))),
        onFileReport: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen(tenantId: widget.userData['id']))),
        onViewStatus: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TenantReportsListScreen(tenantId: widget.userData['id']))),
      ),
      TenantPaymentHistoryScreen(tenantId: widget.userData['id']),
      _buildSimpleProfileView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("HELLO, $tenantName", style: const TextStyle(color: Colors.white, fontSize: 16)), 
        backgroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : RefreshIndicator(onRefresh: fetchData, child: pages[_selectedIndex]),
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

  Widget _buildSimpleProfileView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40))),
        const SizedBox(height: 20),
        
        EditableField(label: "Email", controller: _emailController, icon: Icons.email, enabled: isEditing),
        EditableField(label: "Contact", controller: _contactController, icon: Icons.phone, enabled: isEditing),
        
        // LALABAS LANG ITONG FIELD NA ITO PAG NAKA-EDIT MODE
        if (isEditing) 
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: EditableField(
              label: "New Password (Leave blank if no change)", 
              controller: _passwordController, 
              icon: Icons.lock, 
              enabled: true,
              // obscureText: true, // Siguraduhin na ang EditableField mo ay may ganito
            ),
          ),
          
        const SizedBox(height: 20),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isEditing ? Colors.green : Colors.indigo[900],
            padding: const EdgeInsets.symmetric(vertical: 12)
          ),
          onPressed: () {
            if (isEditing) {
              _handleSaveProfile(); // Tatawag sa API pag "Save Changes"
            } else {
              setState(() => isEditing = true); // Mag-e-enable ang fields pag "Edit Profile"
            }
          }, 
          child: Text(
            isEditing ? "Save Changes" : "Edit Profile", 
            style: const TextStyle(color: Colors.white)
          )
        ),
        
        const Divider(height: 40),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red), 
          title: const Text("Logout", style: TextStyle(color: Colors.red)), 
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()))
        ),
      ],
    );
  }
}