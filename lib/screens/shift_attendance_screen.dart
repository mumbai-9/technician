import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/neumorphic_style.dart';

class ShiftAttendanceScreen extends StatefulWidget {
  const ShiftAttendanceScreen({super.key});

  @override
  State<ShiftAttendanceScreen> createState() => _ShiftAttendanceScreenState();
}

class _ShiftAttendanceScreenState extends State<ShiftAttendanceScreen> {
  bool isLoading = true;
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  Map<String, dynamic> monthlyData = {};
  List<dynamic> attendances = [];
  Map<String, dynamic> summary = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlyAttendance();
  }

  Future<void> _loadMonthlyAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final technicianId = await AuthService.getTechnicianId() ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      final result = await ApiService.getMonthlyAttendance(
        technicianId: technicianId,
        month: selectedMonth,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          monthlyData = result['data'];
          attendances = result['data']['attendances'] ?? [];
          summary = result['data']['summary'] ?? {};
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'half_day':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'half_day':
        return 'Half Day';
      case 'absent':
        return 'Absent';
      default:
        return 'No Data';
    }
  }

  Map<DateTime, dynamic>? _getMarkedDates() {
    Map<DateTime, dynamic> events = {};
    for (var att in attendances) {
      try {
        final date = DateTime.parse(att['date']);
        events[DateTime(date.year, date.month, date.day)] = att;
      } catch (e) {
        // Skip invalid dates
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthlyAttendance,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMonthlyAttendance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 20),
                    _buildCalendar(),
                    const SizedBox(height: 20),
                    _buildAttendanceList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalDays = summary['total_days'] ?? 0;
    final presentDays = summary['present_days'] ?? 0;
    final halfDays = summary['half_days'] ?? 0;
    final absentDays = summary['absent_days'] ?? 0;
    final totalHours = summary['total_hours'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Days',
                totalDays.toString(),
                Colors.blue[700]!,
                Icons.calendar_today,
              ),
              _buildSummaryItem(
                'Total Hours',
                totalHours.toStringAsFixed(1),
                Colors.purple[700]!,
                Icons.access_time,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Present',
                presentDays.toString(),
                Colors.green[700]!,
                Icons.check_circle,
              ),
              _buildSummaryItem(
                'Half Day',
                halfDays.toString(),
                Colors.orange[700]!,
                Icons.timelapse,
              ),
              _buildSummaryItem(
                'Absent',
                absentDays.toString(),
                Colors.red[700]!,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final date = DateTime.parse('$selectedMonth-01');
              final newDate = DateTime(date.year, date.month - 1);
              setState(() {
                selectedMonth = DateFormat('yyyy-MM').format(newDate);
                focusedDay = newDate;
              });
              _loadMonthlyAttendance();
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.parse('$selectedMonth-01')),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final date = DateTime.parse('$selectedMonth-01');
              final newDate = DateTime(date.year, date.month + 1);
              if (newDate
                  .isBefore(DateTime.now().add(const Duration(days: 31)))) {
                setState(() {
                  selectedMonth = DateFormat('yyyy-MM').format(newDate);
                  focusedDay = newDate;
                });
                _loadMonthlyAttendance();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final markedDates = _getMarkedDates();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            this.selectedDay = selectedDay;
            this.focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue[300],
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (markedDates != null &&
                markedDates.containsKey(normalizedDate)) {
              final att = markedDates[normalizedDate];
              final status = att['calculated_status'] ?? '';
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (attendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ATTENDANCE DETAILS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...attendances.map((att) => _buildAttendanceCard(att)),
      ],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> att) {
    final date = att['date'] ?? '';
    final startTime = att['shift_start_time'] ?? '-';
    final endTime = att['shift_end_time'] ?? '-';
    final hours = att['total_hours_worked'] ?? 0;
    final status = att['calculated_status'] ?? '';
    final value = att['attendance_value'] ?? 0;
    final notes = att['notes'] ?? '';

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
                DateFormat('dd MMM yyyy, EEEE').format(DateTime.parse(date)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo('Start', startTime, Icons.login),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo('End', endTime, Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Total: ${hours.toStringAsFixed(2)} hours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                'Value: $value day${value != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
