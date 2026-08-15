import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LeaveApplyScreen extends StatefulWidget {
  const LeaveApplyScreen({super.key});

  @override
  State<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends State<LeaveApplyScreen> {
  bool _isLoading = true;
  int? _technicianId;
  String selectedLeaveType = 'sick';
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController reasonController = TextEditingController();

  // Leave balance (no limitation)
  int? _totalLeaves; // null = no limit
  int _usedLeaves = 0;
  int? _remainingLeaves; // null = no limit
  int _pendingLeaves = 0;

  // Leave history
  List<Map<String, dynamic>> _leaveHistory = [];

  final Map<String, String> leaveTypes = {
    'sick': 'Sick Leave',
    'casual': 'Casual Leave',
    'emergency': 'Emergency Leave',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final techId = await AuthService.getDbId();

    if (techId != null && techId > 0) {
      setState(() {
        _technicianId = techId;
      });
      await _loadLeaveData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLeaveData() async {
    if (_technicianId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getLeaveRequests(
        technicianId: _technicianId!,
      );

      if (response['success'] == true) {
        final data = response['data'];

        // Update leave balance (no limitation)
        final balance = data['leave_balance'];
        setState(() {
          _totalLeaves = balance['total']; // null = no limit
          _usedLeaves = balance['used'] ?? 0;
          _remainingLeaves = balance['remaining']; // null = no limit
        });

        // Update leave history
        final requests = data['leave_requests'] as List;
        setState(() {
          _leaveHistory = requests.map((item) {
            return {
              'id': item['id'],
              'type': item['leave_type'],
              'start_date': item['start_date'],
              'end_date': item['end_date'],
              'days': item['total_days'],
              'reason': item['reason'],
              'status': item['status'],
              'admin_notes': item['admin_notes'],
            };
          }).toList();

          // Count pending leaves
          _pendingLeaves =
              _leaveHistory.where((l) => l['status'] == 'pending').length;
        });
      }
    } catch (e) {
      print('Error loading leave data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Leave Apply'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Apply'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaveData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLeaveData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeaveBalance(),
                  const SizedBox(height: 24),
                  _buildLeaveForm(),
                  const SizedBox(height: 24),
                  _buildLeaveHistory(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: const Text(
                  'No Limit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                    'Used', _usedLeaves.toString(), Colors.blue[600]!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard(
                    'Pending', _pendingLeaves.toString(), Colors.orange[600]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: 12,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply for Leave',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Leave Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: DropdownButton<String>(
              value: selectedLeaveType,
              isExpanded: true,
              underline: const SizedBox(),
              items: leaveTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLeaveType = newValue!;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDatePicker(
                      startDate != null
                          ? DateFormatter.formatDate(startDate!)
                          : 'Select Date',
                      () => _selectDate(context, true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDatePicker(
                      endDate != null
                          ? DateFormatter.formatDate(endDate!)
                          : 'Select Date',
                      () => _selectDate(context, false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Reason',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter reason for leave...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.blue[700]!,
              borderRadius: 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _submitLeave();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text(
                    'SUBMIT LEAVE REQUEST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color:
                    text == 'Select Date' ? Colors.grey[600] : Colors.black87,
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (startDate == null || endDate == null || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_technicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data not found. Please login again.')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.submitLeaveRequest(
        technicianId: _technicianId!,
        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
        leaveType: selectedLeaveType,
        reason: reasonController.text,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ??
                  'Leave request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Clear form
        setState(() {
          startDate = null;
          endDate = null;
          reasonController.clear();
        });

        // Reload data
        await _loadLeaveData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? 'Failed to submit leave request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

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

  Widget _buildLeaveHistory() {
    if (_leaveHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
            child: Center(
              child: Text(
                'No leave requests found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Leave History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ..._leaveHistory.map((leave) => _buildLeaveCard(leave)),
      ],
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final status = leave['status'].toString();
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';

    Color statusColor = Colors.orange[600]!;
    if (isApproved) statusColor = Colors.green[600]!;
    if (isRejected) statusColor = Colors.red[600]!;

    String statusText = status[0].toUpperCase() + status.substring(1);

    final startDate = DateFormatter.formatDate(leave['start_date']);
    final endDate = DateFormatter.formatDate(leave['end_date']);
    final leaveTypeName = leaveTypes[leave['type']] ?? leave['type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leaveTypeName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                  color: statusColor,
                  borderRadius: 8,
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$startDate - $endDate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${leave['days']} day(s)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (leave['admin_notes'] != null &&
              leave['admin_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Notes:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leave['admin_notes'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}
