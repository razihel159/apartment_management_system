import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Gamitin ang 10.0.2.2 kung Android Emulator, localhost kung Web/Windows
  static const String baseUrl = "http://localhost:3000/api";

  // ================= 1. AUTHENTICATION =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "data": data
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"success": false, "message": "Error connecting to server"}
      };
    }
  }

  // ================= 2. DASHBOARD STATS =================
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rooms/dashboard-stats'));
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      print("Dashboard Stats Error: $e");
      return {};
    }
  }

  // ================= 3. ROOM MANAGEMENT =================
  Future<List<dynamic>> getRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rooms'));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      print("Get Rooms Error: $e");
      return [];
    }
  }

  Future<bool> addRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(roomData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Add Room Error: $e");
      return false;
    }
  }

  Future<bool> updateRoom(int id, Map<String, dynamic> roomData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/rooms/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(roomData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Room Error: $e");
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/rooms/delete/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Room Error: $e");
      return false;
    }
  }

  // ================= 4. TENANT MANAGEMENT =================
  
  // DAGDAG NA DITO ANG UPDATED LOGIC MO:
  Future<List<dynamic>> getTenants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tenants'));
      if (response.statusCode == 200) {
        // Dahil 'res.json(r)' ang nasa backend mo, ang response.body ay mismong List.
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Get Tenants Error: $e");
      return [];
    }
  }

  Future<bool> addTenant(Map<String, dynamic> tenantData) async {
    try {
      // Tandaan: Ang tenantData ay dapat may 'name' at 'contact' base sa SQL mo
      final response = await http.post(
        Uri.parse('$baseUrl/tenants/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tenantData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Add Tenant Error: $e");
      return false;
    }
  }

  Future<bool> deleteTenant(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/tenants/delete/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Tenant Error: $e");
      return false;
    }
  }

  // ================= 5. RENT & PAYMENTS =================
  Future<List<dynamic>> getTenantBalances() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/payments/balances'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print("Error in getTenantBalances: $e");
      return [];
    }
  }

  // ================= 6. REPORTS =================
  Future<List<dynamic>> getAllReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports')); 
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      print("Get Reports Error: $e");
      return [];
    }
  }
}