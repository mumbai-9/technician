import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../utils/neumorphic_style.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${job.time}    ${job.date}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name:', job.name),
          const SizedBox(height: 8),
          _buildInfoRow('Address:', job.address),
          const SizedBox(height: 8),
          _buildInfoRow('Service:', job.service),
          const SizedBox(height: 8),
          _buildInfoRow('Treatment:', job.treatment),
          const SizedBox(height: 8),
          _buildInfoRow('Area:', job.area),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Grab',
                  Colors.blue[700]!,
                  onTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Direction',
                  Colors.purple[700]!,
                  () => _launchMaps(job.address),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Call',
                  Colors.brown[700]!,
                  () => _makePhoneCall(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Admin Note',
                  Colors.grey[600]!,
                  () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                color: Colors.green[700]!,
                borderRadius: 12,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 14),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: const Text(
                    'Paid Type: Cash',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration:
                    NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 10),
                child: Text(
                  'Amount: ${job.amount.toInt()} Rs.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: color,
        borderRadius: 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchMaps(String address) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _makePhoneCall() async {
    final Uri url = Uri.parse('tel:+1234567890');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
