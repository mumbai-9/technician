import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../models/branch.dart';

class BranchDetailScreen extends StatefulWidget {
  final int branchId;

  const BranchDetailScreen({super.key, required this.branchId});

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  Branch? branch;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBranchDetails();
  }

  Future<void> _loadBranchDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getBranchDetails(widget.branchId);

      if (result['success'] == true) {
        setState(() {
          branch = Branch.fromJson(result['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load branch details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: NeumorphicStyle.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 10),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Branch Details',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 60, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadBranchDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      _buildContactCard(),
                      const SizedBox(height: 20),
                      _buildLocationCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration:
                  NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 50),
              child: Icon(
                Icons.business,
                size: 50,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              branch!.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration:
                  NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 20),
              child: Text(
                'Code: ${branch!.code}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: branch!.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                branch!.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: branch!.isActive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.phone,
            label: 'Phone',
            value: branch!.phone,
            onTap: () => _makePhoneCall(branch!.phone),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.email,
            label: 'Email',
            value: branch!.email,
            onTap: () => _sendEmail(branch!.email),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationItem(
            icon: Icons.location_on,
            label: 'Address',
            value: branch!.address,
          ),
          const SizedBox(height: 12),
          _buildLocationItem(
            icon: Icons.location_city,
            label: 'City',
            value: branch!.city,
          ),
          const SizedBox(height: 12),
          _buildLocationItem(
            icon: Icons.map,
            label: 'State',
            value: branch!.state,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
