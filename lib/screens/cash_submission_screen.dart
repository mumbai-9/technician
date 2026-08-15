import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';

class CashSubmissionScreen extends StatefulWidget {
  const CashSubmissionScreen({super.key});

  @override
  State<CashSubmissionScreen> createState() => _CashSubmissionScreenState();
}

class _CashSubmissionScreenState extends State<CashSubmissionScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  bool isLoadingCollectors = true;

  double totalPendingAmount = 0;
  List<Map<String, dynamic>> pendingJobs = [];
  List<int> selectedJobIds = [];
  List<Map<String, dynamic>> cashCollectors = [];
  int? selectedCollectorId;

  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPendingCash(),
      _loadCashCollectors(),
    ]);
  }

  Future<void> _loadCashCollectors() async {
    setState(() {
      isLoadingCollectors = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      final result = await ApiService.getCashCollectorsByBranch(technicianId);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          cashCollectors = List<Map<String, dynamic>>.from(result['data']);
          isLoadingCollectors = false;
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load cash collectors');
      }
    } catch (e) {
      setState(() {
        isLoadingCollectors = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cash collectors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPendingCash() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      final result = await ApiService.getPendingCashSubmissions(technicianId);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          totalPendingAmount =
              (result['data']['total_pending_amount'] ?? 0).toDouble();
          pendingJobs =
              List<Map<String, dynamic>>.from(result['data']['jobs'] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitCash() async {
    if (selectedJobIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one job'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedCollectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cash collector'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      final result = await ApiService.submitCashToCollector(
        technicianId: technicianId,
        jobIds: selectedJobIds,
        cashCollectorId: selectedCollectorId!,
        notes: notesController.text,
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (result['success'] == true) {
        final collectorName = result['data']['collected_by']['name'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Cash submitted successfully to $collectorName! Amount: ₹${result['data']['total_amount']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset and reload
        setState(() {
          selectedJobIds.clear();
          selectedCollectorId = null;
          notesController.clear();
        });
        _loadPendingCash();
      } else {
        throw Exception(result['message'] ?? 'Failed to submit cash');
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

  double _getSelectedAmount() {
    double total = 0;
    for (var jobId in selectedJobIds) {
      final job = pendingJobs.firstWhere(
        (j) => j['job_id'] == jobId,
        orElse: () => {},
      );
      if (job.isNotEmpty) {
        total += (job['amount'] ?? 0).toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Cash'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading || isLoadingCollectors
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildCashCollectorDropdown(),
                    const SizedBox(height: 20),
                    _buildNotesInput(),
                    const SizedBox(height: 20),
                    _buildPendingJobsList(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final selectedAmount = _getSelectedAmount();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pending:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${totalPendingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${selectedAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${selectedJobIds.length} of ${pendingJobs.length} jobs selected',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCollectorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBMIT CASH TO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
          child: cashCollectors.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No cash collectors available in your branch',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedCollectorId,
                    hint: const Text('Select Cash Collector'),
                    items: cashCollectors.map((collector) {
                      return DropdownMenuItem<int>(
                        value: collector['id'] as int,
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    collector['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    collector['phone'] ?? '',
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
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCollectorId = value;
                      });
                    },
                  ),
                ),
        ),
        if (selectedCollectorId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cash will be collected by: ${cashCollectors.firstWhere((c) => c['id'] == selectedCollectorId)['name']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this submission...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingJobsList() {
    if (pendingJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'No Pending Cash',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All cash has been submitted!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PENDING JOBS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (selectedJobIds.length == pendingJobs.length) {
                    selectedJobIds.clear();
                  } else {
                    selectedJobIds =
                        pendingJobs.map((j) => j['job_id'] as int).toList();
                  }
                });
              },
              child: Text(
                selectedJobIds.length == pendingJobs.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...pendingJobs.map((job) => _buildJobCard(job)),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobId = job['job_id'] as int;
    final isSelected = selectedJobIds.contains(jobId);
    final amount = (job['amount'] ?? 0).toDouble();
    final customerName = job['customer_name'] ?? 'N/A';
    final service = job['service'] ?? 'N/A';
    final paymentDate = job['payment_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NeumorphicStyle.neumorphicDecoration(
        borderRadius: 12,
        color: isSelected ? Colors.green[50] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedJobIds.remove(jobId);
              } else {
                selectedJobIds.add(jobId);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[700] : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected ? Colors.green[700]! : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid: ${_formatDate(paymentDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = selectedJobIds.isNotEmpty &&
        selectedCollectorId != null &&
        !isSubmitting;

    return Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: canSubmit ? Colors.green[700]! : Colors.grey[400]!,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? _submitCash : null,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        canSubmit
                            ? 'SUBMIT ₹${_getSelectedAmount().toStringAsFixed(2)}'
                            : 'SELECT COLLECTOR & JOBS',
                        style: const TextStyle(
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
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormatter.formatDate(date);
    } catch (e) {
      return dateStr;
    }
  }
}
