import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

/// Debug Information Screen
/// Shows current API configuration and environment details
/// Useful for troubleshooting connection issues
class DebugInfoScreen extends StatelessWidget {
  const DebugInfoScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Environment Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Current Environment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getEnvironmentIcon(),
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ApiConfig.environmentName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // API URL Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Colors.green[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'API Base URL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, ApiConfig.baseUrl),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ApiConfig.baseUrl,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  color: Colors.green[900],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.copy,
                              size: 18,
                              color: Colors.green[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to copy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configuration Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Mode',
                      ApiConfig.isDevelopment
                          ? 'Development'
                          : (ApiConfig.isDemo ? 'Demo' : 'Production'),
                      ApiConfig.isDevelopment
                          ? Colors.orange
                          : (ApiConfig.isDemo ? Colors.blue : Colors.green),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Environment',
                      ApiConfig.currentEnvironment.name.toUpperCase(),
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'How to Change',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To change the environment:\n\n'
                      '1. Open: lib/config/api_config.dart\n'
                      '2. Change: currentEnvironment\n'
                      '3. Available: production, demo, physicalDevice, emulator\n'
                      '4. Save and restart the app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // You can add a test API call here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test connection feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEnvironmentIcon() {
    switch (ApiConfig.currentEnvironment) {
      case Environment.emulator:
        return Icons.phone_android;
      case Environment.physicalDevice:
        return Icons.smartphone;
      case Environment.demo:
        return Icons.cloud_queue;
      case Environment.production:
        return Icons.cloud;
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
