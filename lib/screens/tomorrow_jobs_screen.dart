import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job_model.dart';
import '../models/job.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class TomorrowJobsScreen extends StatefulWidget {
  const TomorrowJobsScreen({super.key});

  @override
  State<TomorrowJobsScreen> createState() => _TomorrowJobsScreenState();
}

class _TomorrowJobsScreenState extends State<TomorrowJobsScreen> {
  bool isLoading = true;
  List<Job> tomorrowJobs = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTomorrowJobs();
  }

  Future<void> _loadTomorrowJobs() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userData = await AuthService.getUserData();
      final technicianDbId = userData['db_id'] ?? 0;

      if (technicianDbId == 0) {
        setState(() {
          errorMessage = 'Invalid technician ID';
          isLoading = false;
        });
        return;
      }

      final result = await ApiService.getTomorrowJobs(technicianDbId);

      if (result['success'] == true) {
        if (result['on_leave'] == true) {
          setState(() {
            tomorrowJobs = [];
            errorMessage = result['message'];
            isLoading = false;
          });
        } else {
          final List<dynamic> jobsData = result['data'] ?? [];
          setState(() {
            tomorrowJobs = jobsData.map((json) => Job.fromJson(json)).toList();
            // Sort jobs by scheduled time in ascending order
            tomorrowJobs.sort((a, b) {
              // Handle null scheduled dates - put them at the end
              if (a.scheduledDate == null && b.scheduledDate == null) return 0;
              if (a.scheduledDate == null) return 1;
              if (b.scheduledDate == null) return -1;
              
              return a.scheduledDate!.compareTo(b.scheduledDate!);
            });
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load tomorrow\'s jobs';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading tomorrow\'s jobs: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowFormatted = DateFormatter.formatDate(tomorrow);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tomorrow\'s Jobs - $tomorrowFormatted',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTomorrowJobs,
          color: Colors.blue[700],
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : errorMessage != null
                  ? _buildErrorState()
                  : _buildJobsList(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 80,
                color: Colors.orange[400],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTomorrowJobs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    if (tomorrowJobs.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 80,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No jobs scheduled for tomorrow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enjoy your free day!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[300]!, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a preview of tomorrow\'s jobs. You cannot grab or start these jobs until tomorrow.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Jobs count
          Text(
            '${tomorrowJobs.length} job${tomorrowJobs.length == 1 ? '' : 's'} scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          // Jobs list
          ...tomorrowJobs.map((job) {
            // Format the booking/scheduled time
            String displayTime = 'Not scheduled';
            if (job.scheduledDate != null) {
              displayTime = DateFormat('hh:mm a').format(job.scheduledDate!);
            }

            // Convert Job to JobModel for consistency
            final jobModel = JobModel(
              id: job.id.toString(),
              name: job.customerName,
              address: job.address,
              service: job.service,
              treatment: 'Standard',
              area: '${job.city}, ${job.state}',
              time: displayTime,
              date: job.scheduledDate != null
                  ? DateFormatter.formatDate(job.scheduledDate!)
                  : 'Not scheduled',
              paidType: 'Pending',
              amount: job.amount ?? 0,
              note: job.jobNotes,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTomorrowJobCard(jobModel, job),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTomorrowJobCard(JobModel jobModel, Job job) {
    // Determine status color and icon
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;

    switch (job.status) {
      case 'rescheduled':
        statusColor = Colors.purple[700]!;
        statusBgColor = Colors.purple[100]!;
        statusIcon = Icons.schedule;
        statusText = 'Rescheduled';
        break;
      default: // assigned
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[100]!;
        statusIcon = Icons.assignment;
        statusText = 'Assigned';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${jobModel.time}    ${jobModel.date}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Job Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Preview Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.preview,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PREVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Complaint Badge (if this is a complaint revisit job)
                  if (job.complaintId != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.report_problem,
                            size: 14,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'COMPLAINT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildJobInfoRow('Name:', jobModel.name),
          const SizedBox(height: 8),
          _buildJobInfoRow('Address:', jobModel.address),
          const SizedBox(height: 8),
          _buildJobInfoRow('Service:', jobModel.service),
          const SizedBox(height: 8),
          _buildJobInfoRow('Area:', jobModel.area),
          if (jobModel.note != null && jobModel.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildJobInfoRow('Notes:', jobModel.note!),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoRow(String label, String value) {
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
}
