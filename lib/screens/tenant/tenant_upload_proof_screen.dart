import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // Para ma-detect kung Chrome ang gamit

class TenantUploadProofScreen extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const TenantUploadProofScreen({
    super.key, 
    required this.tenantId, 
    required this.tenantName
  });

  @override
  State<TenantUploadProofScreen> createState() => _TenantUploadProofScreenState();
}

class _TenantUploadProofScreenState extends State<TenantUploadProofScreen> {
  File? _image;           // Para sa Mobile
  XFile? _pickedFile;     // Para sa Web/Chrome compatibility
  final _picker = ImagePicker();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  bool _isLoading = false;

  // Function para pumili ng image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _image = File(pickedFile.path);
      });
    }
  }

  // Function para i-upload ang proof
  Future<void> _submitProof() async {
    if (_pickedFile == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and enter amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('http://localhost:3000/submit-proof')
      );

      request.fields['tenant_id'] = widget.tenantId;
      request.fields['amount'] = _amountController.text;
      request.fields['reference_number'] = _refController.text;

      if (kIsWeb) {
        // Upload logic para sa Chrome/Web
        var bytes = await _pickedFile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'proof_image', 
            bytes, 
            filename: _pickedFile!.name
          )
        );
      } else {
        // Upload logic para sa Mobile
        request.files.add(
          await http.MultipartFile.fromPath('proof_image', _image!.path)
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof submitted successfully!")),
        );
        Navigator.pop(context); 
      } else {
        throw Exception("Failed to upload. Status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Payment Proof")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Tenant: ${widget.tenantName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Image Preview Box (Fix para sa Chrome Red Screen)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: _pickedFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          Text("Tap to select Receipt Screenshot"),
                        ],
                      )
                    : kIsWeb 
                        ? Image.network(_pickedFile!.path, fit: BoxFit.contain) // Para sa Chrome
                        : Image.file(_image!, fit: BoxFit.contain),             // Para sa Phone
              ),
            ),
            
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount Paid", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(labelText: "Reference Number (Optional)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitProof,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Text("Submit Payment Proof", style: TextStyle(color: Colors.white)),
                ),
          ],
        ),
      ),
    );
  }
}