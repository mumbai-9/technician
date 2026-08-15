import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildEmergencyContact(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildFAQ(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 64, color: Colors.blue[700]),
          const SizedBox(height: 16),
          const Text(
            'Emergency Support',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '24/7 Available',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
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
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'CALL SUPPORT',
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
              'Report an Issue', Icons.report_problem, Colors.red[600]!),
          const SizedBox(height: 12),
          _buildActionButton(
              'Technical Support', Icons.build, Colors.blue[600]!),
          const SizedBox(height: 12),
          _buildActionButton(
              'App Feedback', Icons.feedback, Colors.orange[600]!),
          const SizedBox(height: 12),
          _buildActionButton(
              'Training Videos', Icons.play_circle, Colors.purple[600]!),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Container(
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: ListTile(
        tileColor: NeumorphicStyle.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: NeumorphicStyle.coloredNeumorphicDecoration(
            color: color,
            borderRadius: 8,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _buildFAQ() {
    final faqs = [
      {
        'q': 'How to mark attendance?',
        'a': 'Go to My Attendance and tap Mark Attendance button.'
      },
      {
        'q': 'How to apply for leave?',
        'a': 'Navigate to Leave Apply, fill the form and submit.'
      },
      {
        'q': 'How to track expenses?',
        'a': 'Use Today Expense to add and track your daily expenses.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...faqs.map((faq) => _buildFAQCard(faq)),
      ],
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faq['q'],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            faq['a'],
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
