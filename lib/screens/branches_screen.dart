import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../models/branch.dart';
import 'branch_detail_screen.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<Branch> branches = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getBranches();

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          branches = data.map((json) => Branch.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load branches';
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
          'Branches',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  NeumorphicStyle.neumorphicDecoration(borderRadius: 10),
              child: const Icon(Icons.refresh, color: Colors.black87),
            ),
            onPressed: _loadBranches,
          ),
          const SizedBox(width: 10),
        ],
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
                        onPressed: _loadBranches,
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
              : branches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No branches found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBranches,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: branches.length,
                        itemBuilder: (context, index) {
                          final branch = branches[index];
                          return _buildBranchCard(branch);
                        },
                      ),
                    ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BranchDetailScreen(branchId: branch.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: NeumorphicStyle.neumorphicInsetDecoration(
                          borderRadius: 12),
                      child: Icon(
                        Icons.business,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${branch.code}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: branch.isActive
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        branch.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: branch.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on, branch.address),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.location_city, '${branch.city}, ${branch.state}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.phone, branch.phone),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoRow(Icons.email, branch.email),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
