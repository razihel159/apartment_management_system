import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/api_service.dart';
import 'widgets/tenant_widgets.dart'; // Import ang bagong widgets

class TenantUploadProofScreen extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const TenantUploadProofScreen({super.key, required this.tenantId, required this.tenantName});

  @override
  State<TenantUploadProofScreen> createState() => _TenantUploadProofScreenState();
}

class _TenantUploadProofScreenState extends State<TenantUploadProofScreen> {
  XFile? _pickedFile;
  final _picker = ImagePicker();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _pickedFile = pickedFile);
  }

  Future<void> _submitProof() async {
    if (_pickedFile == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete the form")));
      return;
    }
    setState(() => _isLoading = true);
    final success = await ApiService().uploadPaymentProof(
      tenantId: widget.tenantId,
      amount: _amountController.text,
      refNumber: _refController.text,
      pickedFile: _pickedFile,
      isWeb: kIsWeb,
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Proof"), backgroundColor: Colors.indigo[900], foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Tenant: ${widget.tenantName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ProofImageSelector(pickedFile: _pickedFile, onTap: _pickImage), // Galing sa tenant_widgets.dart
            const SizedBox(height: 20),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _refController, decoration: const InputDecoration(labelText: "Ref #", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submitProof, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}