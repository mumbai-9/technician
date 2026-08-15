import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/shift_attendance_screen.dart';
import '../screens/kilometer_screen.dart';

class WorkingHoursWidget extends StatefulWidget {
  const WorkingHoursWidget({super.key});

  @override
  State<WorkingHoursWidget> createState() => _WorkingHoursWidgetState();
}

class _WorkingHoursWidgetState extends State<WorkingHoursWidget> {
  Timer? _timer;
  bool isLoading = true;
  bool shiftStarted = false;
  bool shiftEnded = false;
  String shiftStartTime = '';
  String shiftEndTime = '';
  double totalHours = 0;
  double currentHours = 0;
  String calculatedStatus = 'not_started';
  bool isStarting = false;
  bool isEnding = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (shiftStarted && !shiftEnded) {
        _loadTodayData();
      }
    });
  }

  Future<void> _loadTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) return;

      final result = await ApiService.getTodayWorkingHours(technicianId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (mounted) {
          setState(() {
            shiftStarted = data['shift_started'] ?? false;
            shiftEnded = data['shift_ended'] ?? false;
            shiftStartTime = data['shift_start_time'] ?? '';
            shiftEndTime = data['shift_end_time'] ?? '';
            totalHours = (data['total_hours_worked'] ?? 0).toDouble();
            currentHours = (data['current_hours'] ?? 0).toDouble();
            calculatedStatus = data['calculated_status'] ?? 'not_started';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _startShift() async {
    // Navigate to kilometer screen for start reading
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KilometerScreen(isStart: true),
      ),
    );

    // Reload data after returning
    if (result == true || mounted) {
      _loadTodayData();
    }
  }

  Future<void> _endShift() async {
    // Navigate to kilometer screen for end reading
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KilometerScreen(isStart: false),
      ),
    );

    // Reload data after returning
    if (result == true || mounted) {
      _loadTodayData();
    }
  }

  Color _getStatusColor() {
    if (!shiftStarted) return Colors.grey;
    if (shiftEnded) {
      switch (calculatedStatus) {
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
    return Colors.blue;
  }

  String _getStatusText() {
    if (!shiftStarted) return 'Not Started';
    if (shiftEnded) {
      switch (calculatedStatus) {
        case 'present':
          return 'Present';
        case 'half_day':
          return 'Half Day';
        case 'absent':
          return 'Absent';
        default:
          return 'Completed';
      }
    }
    return 'In Progress';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5ECF7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5ECF7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and calendar icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Shift',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123A6B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shiftEnded ? 'Shift completed' : 'Track your working hours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShiftAttendanceScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF3FF), Color(0xFFDCEBFF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 24,
                    color: Color(0xFF2E6CDE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hours display card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor().withValues(alpha: 0.08),
                  _getStatusColor().withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor().withValues(alpha: 0.2),
                        _getStatusColor().withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    shiftStarted && !shiftEnded
                        ? Icons.timer_rounded
                        : Icons.check_circle_rounded,
                    color: _getStatusColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shiftEnded
                            ? '${totalHours.toStringAsFixed(2)} hrs'
                            : shiftStarted
                                ? '${currentHours.toStringAsFixed(2)} hrs'
                                : '0.00 hrs',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time info section
          if (shiftStarted && !shiftEnded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Started at $shiftStartTime',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            )
          else if (shiftEnded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'In: $shiftStartTime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Out: $shiftEndTime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Action buttons
          if (!shiftStarted)
            _buildModernActionButton(
              'START SHIFT',
              Colors.green[700]!,
              Icons.play_arrow_rounded,
              isStarting,
              _startShift,
            )
          else if (!shiftEnded)
            _buildModernActionButton(
              'END SHIFT',
              Colors.red[700]!,
              Icons.stop_rounded,
              isEnding,
              _endShift,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[100]!,
                    Colors.green[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green[200]!,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Shift Completed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    String label,
    Color color,
    IconData icon,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
