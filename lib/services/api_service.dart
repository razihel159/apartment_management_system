import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CONFIGURATION:
  // - Gamitin ang "http://localhost:3000/api" kung Chrome/Web.
  // - Gamitin ang iyong Local IP (e.g. 192.168.1.5:3000/api) kung physical phone.
  static const String baseUrl = "http://localhost:3000/api";

  // --- HELPER PARA SA LISTS (UPDATED PARA SA DB CONNECTIVITY) ---
  List<dynamic> _handleListResponse(http.Response res) {
    // Nagdagdag ng print para makita mo sa VS Code Debug Console kung anong data ang dumadating
    print("DEBUG API RESPONSE [${res.request?.url}]: ${res.body}");

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        // Idinagdag itong mga keys na ito para sigurado ang koneksyon sa DB fields
        if (decoded.containsKey('data')) return decoded['data'];
        if (decoded.containsKey('reports')) return decoded['reports'];
        if (decoded.containsKey('payments')) return decoded['payments'];
      }
    }
    return [];
  }

  // ================= 1. AUTHENTICATION =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return {"statusCode": response.statusCode, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"statusCode": 500, "data": {"success": false, "message": "Server Error"}};
    }
  }

  // ================= 2. ROOM MANAGEMENT (LANDLORD) =================
  Future<List<dynamic>> getRooms() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/rooms'));
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  Future<bool> addRoom(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/rooms/add'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(data)
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/rooms/update/$id'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(data)
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/rooms/delete/$id'));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  // ================= 3. TENANT MANAGEMENT =================
  Future<List<dynamic>> getTenants() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tenants'));
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>?> getTenantProfile(int id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tenants/$id'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Fix: Sinisigurado na kung ang profile ay nakabalot sa 'data', makukuha pa rin
        return (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;
      }
      return null;
    } catch (e) { return null; }
  }

  Future<bool> updateTenantProfile(int id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/tenants/update/$id'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(data)
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  // ================= 4. REPORTS =================
  Future<bool> submitReport(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reports/add'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(data)
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }

  // Para sa Admin: Kunin lahat ng reports
  Future<List<dynamic>> getAllReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/all'));
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  // Para sa Tenant: Kunin ang sariling reports
  Future<List<dynamic>> getTenantReports(int id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/tenant/$id'));
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  // UPDATE STATUS (Landlord side - fixed/in progress)
  Future<bool> updateReportStatus(int reportId, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reports/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'report_id': reportId, 'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<int> getUnreadReportsCount(int id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/reports/unread-count/$id'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['count'] ?? 0;
      }
      return 0;
    } catch (e) { return 0; }
  }

  // ================= 5. PAYMENTS & PROOF UPLOAD =================
  Future<List<dynamic>> getTenantPaymentHistory(int id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/payments/tenant/$id'));
      // Inupdate para gamitin ang helper na marunong mag-check ng 'data' key
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  // --- DAGDAG: ITO ANG KAILANGAN PARA SA RENT MONITORING SCREEN ---
  Future<List<dynamic>> getOverdueTenants() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/payments/overdue'));
      return _handleListResponse(res);
    } catch (e) { return []; }
  }

  Future<bool> uploadPaymentProof({
    required String tenantId,
    required String amount,
    required String refNumber,
    required dynamic pickedFile, 
    required bool isWeb,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/payments/submit-proof'));
      
      request.fields['tenant_id'] = tenantId;
      request.fields['amount'] = amount;
      request.fields['reference_number'] = refNumber;

      if (isWeb) {
        var bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'proof_image', 
          bytes, 
          filename: pickedFile.name
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'proof_image', 
          pickedFile.path
        ));
      }

      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Upload API Error: $e");
      return false;
    }
  }
}