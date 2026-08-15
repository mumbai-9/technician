import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddonServiceScreen extends StatefulWidget {
  final JobModel job;

  const AddonServiceScreen({
    super.key,
    required this.job,
  });

  @override
  State<AddonServiceScreen> createState() => _AddonServiceScreenState();
}

class _AddonServiceScreenState extends State<AddonServiceScreen> {
  final List<Map<String, dynamic>> _addonServices = [];
  bool isSubmitting = false;

  void _addService() {
    setState(() {
      _addonServices.add({
        'service_name': '',
        'amount': 0.0,
        'nameController': TextEditingController(),
        'amountController': TextEditingController(),
      });
    });
  }

  void _removeService(int index) {
    setState(() {
      _addonServices[index]['nameController'].dispose();
      _addonServices[index]['amountController'].dispose();
      _addonServices.removeAt(index);
    });
  }

  Future<void> _submitServices() async {
    // Validate all services
    for (var service in _addonServices) {
      if (service['nameController'].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter service name for all services'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final amount = double.tryParse(service['amountController'].text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid amount for all services'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_addonServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      // Prepare addon services data
      final List<Map<String, dynamic>> services = _addonServices.map((service) {
        return {
          'service_name': service['nameController'].text.trim(),
          'amount': double.parse(service['amountController'].text),
        };
      }).toList();

      final result = await ApiService.addAddonServices(
        jobId: jobId,
        technicianId: technicianId,
        addonServices: services,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add-on services added successfully!'),
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
            content: Text(result['message'] ?? 'Failed to add services'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
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
  void dispose() {
    for (var service in _addonServices) {
      service['nameController'].dispose();
      service['amountController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-On Services'),
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
                              'Add additional services performed during this job',
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

                    // Services List
                    if (_addonServices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: NeumorphicStyle.neumorphicDecoration(
                            borderRadius: 16),
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No add-on services yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click the button below to add services',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._addonServices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: NeumorphicStyle.neumorphicDecoration(
                              borderRadius: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeService(index),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: service['nameController'],
                                decoration: InputDecoration(
                                  labelText: 'Service Name',
                                  hintText: 'e.g., Extra Room Treatment',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.build),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: service['amountController'],
                                decoration: InputDecoration(
                                  labelText: 'Amount (Rs)',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.currency_rupee),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),

                    // Add Service Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addService,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Service'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.blue[700]!),
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
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
                  color: _addonServices.isEmpty
                      ? Colors.grey[400]!
                      : Colors.blue[700]!,
                  borderRadius: 12,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (isSubmitting || _addonServices.isEmpty)
                        ? null
                        : _submitServices,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: isSubmitting
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
                                  'SAVE ADD-ON SERVICES',
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
