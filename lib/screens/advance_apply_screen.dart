import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';

class AdvanceApplyScreen extends StatefulWidget {
  const AdvanceApplyScreen({super.key});

  @override
  State<AdvanceApplyScreen> createState() => _AdvanceApplyScreenState();
}

class _AdvanceApplyScreenState extends State<AdvanceApplyScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  String? userId;
  bool isLoading = false;
  List<dynamic> advanceHistory = [];
  Map<String, dynamic> summary = {
    'total_taken': 0.0,
    'pending': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    if (userId != null) {
      _fetchAdvanceRequests();
    }
  }

  Future<void> _fetchAdvanceRequests() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getAdvanceRequests(userId: userId!);
      if (response['success'] == true) {
        setState(() {
          advanceHistory = response['requests'] ?? [];
          summary = response['summary'] ?? {'total_taken': 0.0, 'pending': 0.0};
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching advance requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance Apply'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAdvanceRequests,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummary(),
                      const SizedBox(height: 24),
                      _buildForm(),
                      const SizedBox(height: 24),
                      _buildHistory(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          const Text(
            'Advance Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                    'Total Taken',
                    '₹ ${summary['total_taken'].toStringAsFixed(2)}',
                    Colors.blue[600]!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                    'Pending',
                    '₹ ${summary['pending'].toStringAsFixed(2)}',
                    Colors.orange[600]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Advance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Amount (₹)',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Reason for advance...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.green[700]!,
              borderRadius: 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submitAdvance,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: const Text(
                    'SUBMIT REQUEST',
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

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advance History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (advanceHistory.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No advance requests yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...advanceHistory.map((advance) => _buildHistoryCard(advance)),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> advance) {
    final isApproved = advance['status'] == 'approved';
    final isRejected = advance['status'] == 'rejected';

    Color statusColor = Colors.orange[600]!;
    if (isApproved) statusColor = Colors.green[600]!;
    if (isRejected) statusColor = Colors.red[600]!;

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
                '₹ ${double.parse(advance['amount'].toString()).toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                  color: statusColor,
                  borderRadius: 8,
                ),
                child: Text(
                  advance['status'].toString().toUpperCase(),
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
            advance['reason'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatDate(advance['request_date']),
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (advance['admin_notes'] != null &&
              advance['admin_notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
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
                    advance['admin_notes'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _submitAdvance() async {
    if (amountController.text.isEmpty || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.submitAdvanceRequest(
        userId: userId!,
        amount: double.parse(amountController.text),
        reason: reasonController.text,
        requestDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      setState(() {
        isLoading = false;
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Advance request submitted successfully!')),
          );
        }

        amountController.clear();
        reasonController.clear();

        // Refresh the list
        _fetchAdvanceRequests();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message'] ?? 'Failed to submit advance request')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }
}
