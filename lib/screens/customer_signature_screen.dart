import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../models/job_model.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CustomerSignatureScreen extends StatefulWidget {
  final JobModel job;

  const CustomerSignatureScreen({
    super.key,
    required this.job,
  });

  @override
  State<CustomerSignatureScreen> createState() =>
      _CustomerSignatureScreenState();
}

class _CustomerSignatureScreenState extends State<CustomerSignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _uploadSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide signature first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // Export signature as PNG
      final Uint8List? signatureBytes = await _controller.toPngBytes();

      if (signatureBytes == null) {
        throw Exception('Failed to capture signature');
      }

      // Convert to base64
      final String base64Signature = base64Encode(signatureBytes);

      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      final result = await ApiService.uploadSignature(
        jobId: jobId,
        technicianId: technicianId,
        signature: base64Signature,
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to upload signature'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Signature'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: NeumorphicStyle.neumorphicDecoration(
                          borderRadius: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.blue[700], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.job.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.job.service,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please ask the customer to sign below',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Signature Pad
                    Container(
                      decoration: NeumorphicStyle.neumorphicDecoration(
                          borderRadius: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SIGNATURE PAD',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _controller.clear();
                                  },
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 300,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Signature(
                                controller: _controller,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign above with your finger',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Upload Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Container(
                decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                  color: Colors.blue[700]!,
                  borderRadius: 12,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isUploading ? null : _uploadSignature,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: isUploading
                          ? const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'SAVE SIGNATURE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
