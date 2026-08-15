import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class MyRefScreen extends StatelessWidget {
  const MyRefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Referrals'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildReferralCode(),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 24),
              _buildReferralList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCode() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          const Text(
            'Your Referral Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.blue[700]!,
              borderRadius: 12,
            ),
            child: const Text(
              'REF24DS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.green[700]!,
              borderRadius: 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: const Text(
                    'SHARE CODE',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', '8', Colors.blue[600]!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Active', '5', Colors.green[600]!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Earnings', '₹2400', Colors.orange[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralList() {
    final referrals = [
      {
        'name': 'Rahul Sharma',
        'date': '15 Dec 2025',
        'status': 'Active',
        'earning': 300
      },
      {
        'name': 'Amit Patel',
        'date': '10 Dec 2025',
        'status': 'Active',
        'earning': 300
      },
      {
        'name': 'Suresh Kumar',
        'date': '05 Dec 2025',
        'status': 'Inactive',
        'earning': 0
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Referrals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...referrals.map((ref) => _buildReferralCard(ref)),
      ],
    );
  }

  Widget _buildReferralCard(Map<String, dynamic> ref) {
    final isActive = ref['status'] == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: isActive ? Colors.green[600]! : Colors.grey[600]!,
              borderRadius: 10,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref['name'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  ref['date'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration:
                    NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 6),
                child: Text(
                  ref['status'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${ref['earning']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
