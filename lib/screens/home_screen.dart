import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job_model.dart';
import '../models/job.dart';
import '../widgets/responsive_stats_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/working_hours_widget.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import 'job_detail_screen.dart';
import 'leave_apply_screen.dart';
import 'expense_screen.dart';
import 'kilometer_screen.dart';
import 'chemical_screen.dart';
import 'advance_apply_screen.dart';
import 'cash_submission_screen.dart';
import 'help_screen.dart';
import 'branches_screen.dart';
import 'tomorrow_jobs_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _autoRefreshTimer;
  Timer? _clockTimer;
  bool _isRefreshing = false;

  DateTime _currentTime = DateTime.now();

  String technicianName = '';
  String technicianCode = '';
  String technicianUserId = '';
  String? profilePictureUrl;
  bool isLoading = true;
  List<Job> myJobs = [];
  JobStats stats = JobStats(
    pending: 0,
    completed: 0,
    online: 0,
    cash: 0,
    cashPending: 0,
  );

  // Leave status
  bool isOnLeave = false;
  String? leaveStartDate;
  String? leaveEndDate;
  String? leaveType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLeaveStatus();
    _loadJobs();
    _loadStats();
    _startAutoRefresh();
    _startClock();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _isRefreshing) return;
      _isRefreshing = true;
      try {
        await _loadJobs();
      } catch (e) {
        debugPrint('Auto-refresh failed: $e');
      } finally {
        _isRefreshing = false;
      }
    });
  }

  Future<void> _checkLeaveStatus() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) return;

      final result =
          await ApiService.checkLeaveStatus(technicianId: technicianId);

      if (result['success'] == true && result['on_leave'] == true) {
        final leaveDetails = result['leave_details'];
        setState(() {
          isOnLeave = true;
          leaveStartDate = leaveDetails['start_date'];
          leaveEndDate = leaveDetails['end_date'];
          leaveType = leaveDetails['leave_type'];
        });
      }
    } catch (e) {
      debugPrint('Error checking leave status: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) return;

      final result = await ApiService.getStats(technicianId);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          stats = JobStats(
            pending: result['data']['pending'] ?? 0,
            completed: result['data']['completed'] ?? 0,
            online: (result['data']['online'] ?? 0).toDouble(),
            cash: (result['data']['cash'] ?? 0).toDouble(),
            cashPending: (result['data']['cash_pending'] ?? 0).toDouble(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // First get basic auth data for user_id
      final authData = await AuthService.getUserData();
      final userIdValue = authData['user_id'] ?? '';

      debugPrint('📱 Loading user data from auth: $authData');

      // Always fetch full profile from API to get updated profile picture
      if (userIdValue.isNotEmpty) {
        final profileResponse = await ApiService.getProfile(userIdValue);

        if (!mounted) return;

        if (profileResponse['success'] == true &&
            profileResponse['data'] != null) {
          final data = profileResponse['data'];
          setState(() {
            technicianName = data['name'] ?? '';
            technicianCode = data['code'] ?? '';
            technicianUserId = data['user_id'] ?? '';
            profilePictureUrl = data['profile_picture'];
            isLoading = false;
          });
          debugPrint('✅ Loaded from API: Name=$technicianName, ProfilePic=$profilePictureUrl');
          return;
        }
      }

      // Fallback to auth data if API fails or user_id is empty
      setState(() {
        technicianName = authData['name'] ?? 'Technician';
        technicianCode = authData['code'] ?? '';
        technicianUserId = authData['user_id'] ?? '';
        profilePictureUrl = authData['profile_picture'];
        isLoading = false;
      });
      debugPrint('✅ Loaded from auth (fallback): Name=$technicianName');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadJobs() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianDbId = userData['db_id'] ?? 0;

      if (technicianDbId == 0) {
        debugPrint('❌ Invalid technician ID');
        return;
      }

      final result = await ApiService.getMyJobs(technicianDbId);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> jobsData = result['data'];
        setState(() {
          myJobs = jobsData.map((json) => Job.fromJson(json)).toList();
          // Sort jobs by scheduled time in ascending order
          myJobs.sort((a, b) {
            // Handle null scheduled dates - put them at the end
            if (a.scheduledDate == null && b.scheduledDate == null) return 0;
            if (a.scheduledDate == null) return 1;
            if (b.scheduledDate == null) return -1;

            return a.scheduledDate!.compareTo(b.scheduledDate!);
          });
        });
        debugPrint('✅ Loaded ${myJobs.length} jobs (sorted by time ascending)');
      } else {
        debugPrint('❌ Failed to load jobs: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error loading jobs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7FAFF), Color(0xFFF2F6FF)],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              if (isOnLeave) _buildLeaveBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF2563EB),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: WorkingHoursWidget(),
                        ),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildJobSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _buildDrawer(),
    );
  }

  Widget _buildLeaveBanner() {
    final startDate =
        leaveStartDate != null ? DateFormatter.formatDate(leaveStartDate!) : '';
    final endDate =
        leaveEndDate != null ? DateFormatter.formatDate(leaveEndDate!) : '';

    String leaveTypeName = leaveType ?? 'Leave';
    if (leaveType == 'sick') leaveTypeName = 'Sick Leave';
    if (leaveType == 'casual') leaveTypeName = 'Casual Leave';
    if (leaveType == 'emergency') leaveTypeName = 'Emergency Leave';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F0D8), Color(0xFFFFF8E8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0C96E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.info_outline, color: Colors.orange[700], size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are on $leaveTypeName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $startDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'To: $endDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You cannot receive new job assignments during this period.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Show loading feedback
    setState(() {
      isLoading = true;
    });

    // Reload user data, jobs, and leave status
    await Future.wait([
      _loadUserData(),
      _loadJobs(),
      _loadStats(),
      _checkLeaveStatus(),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data refreshed successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicStyle.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final formattedDate = DateFormatter.formatDate(_currentTime);
    final formattedTime = DateFormat('h:mm a').format(_currentTime);

    return Container(
      margin: padding,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2E6F), Color(0xFF1E5FD8), Color(0xFF4BA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5FD8).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: isLoading
                ? const SizedBox(
                    height: 58,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isSmallScreen ? 24 : 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          backgroundImage: profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl!)
                              : null,
                          child: profilePictureUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                    context, 11),
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              technicianName.isNotEmpty
                                  ? technicianName
                                  : 'Technician',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                    context, 17),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    technicianCode.isNotEmpty
                                        ? 'ID $technicianCode'
                                        : 'Technician',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context, 11),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context, 11),
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context, 11),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Builder(
            builder: (context) => Container(
              width: isSmallScreen ? 42 : 48,
              height: isSmallScreen ? 42 : 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.menu_rounded,
                  size: isSmallScreen ? 22 : 26,
                  color: Colors.white,
                ),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding.left),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C3E8F), Color(0xFF2B6EEB), Color(0xFF62A9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B6EEB).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today overview',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jobs, payments, and service flow in one place.',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 12),
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF3FF), Color(0xFFDCEBFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work_outline_rounded,
                        color: const Color(0xFF2E6CDE),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Job History',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF123A6B),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 18),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: 'Pending',
                        value: stats.pending.toString(),
                        color: Colors.orange[700]!,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: 'Completed',
                        value: stats.completed.toString(),
                        color: Colors.green[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF3FF), Color(0xFFDCEBFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        color: const Color(0xFF2E6CDE),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF123A6B),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 18),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: 'Online',
                        value: stats.online.toInt().toString(),
                        color: Colors.green[600]!,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: 'Cash',
                        value: stats.cash.toInt().toString(),
                        color: Colors.blue[700]!,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: 'Cash Pending',
                        value: stats.cashPending.toInt().toString(),
                        color: Colors.red[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSection() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding.left),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Jobs',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF123A6B),
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D4DA1), Color(0xFF2E6CDE)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TomorrowJobsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tomorrow',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myJobs.length}/2',
                      style: TextStyle(
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E6CDE),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (myJobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.work_outline, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs assigned yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...myJobs.map((job) {
              // Format the booking/scheduled time (when customer booked the service)
              String displayTime = 'Not scheduled';
              if (job.scheduledDate != null) {
                displayTime = DateFormat('hh:mm a').format(job.scheduledDate!);
              }

              // Convert Job to JobModel for JobCard widget
              final jobModel = JobModel(
                id: job.id.toString(),
                name: job.customerName,
                address: job.address,
                service: job.service,
                treatment: job.treatment ?? 'N/A',
                flatSize: job.flatSize,
                area: '${job.city}, ${job.state}',
                time: displayTime, // Show booking/scheduled time
                date: job.scheduledDate != null
                    ? DateFormatter.formatDate(job.scheduledDate!)
                    : 'Not scheduled',
                paidType: 'Pending',
                amount: job.amount ?? 0,
                note: job.jobNotes,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildJobCard(jobModel, job),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel jobModel, Job job) {
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
      case 'in_progress':
        statusColor = Colors.blue[700]!;
        statusBgColor = Colors.blue[100]!;
        statusIcon = Icons.work;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[100]!;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[100]!;
        statusIcon = Icons.assignment;
        statusText = 'Assigned';
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: jobModel,
              jobData: job,
            ),
          ),
        );
        if (result == true) {
          _loadJobs();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${jobModel.time}    ${jobModel.date}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123A6B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: job.isGrabbed
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            job.isGrabbed
                                ? Icons.play_circle_fill
                                : Icons.pending_actions,
                            size: 14,
                            color: job.isGrabbed
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.isGrabbed ? 'Started' : 'Ready to Start',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: job.isGrabbed
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                fontWeight: FontWeight.w700,
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
            const SizedBox(height: 16),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: job.isGrabbed
                        ? [const Color(0xFF0D4DA1), const Color(0xFF2E6CDE)]
                        : [const Color(0xFF147B4B), const Color(0xFF1FA665)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (job.isGrabbed
                              ? const Color(0xFF2E6CDE)
                              : const Color(0xFF1FA665))
                          .withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(
                            job: jobModel,
                            jobData: job,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadJobs();
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            job.isGrabbed
                                ? Icons.visibility
                                : Icons.play_circle_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            job.isGrabbed ? 'View Details' : 'Start Job',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: NeumorphicStyle.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: profilePictureUrl != null
                            ? NetworkImage(profilePictureUrl!)
                            : null,
                        child: profilePictureUrl == null
                            ? const Icon(Icons.person,
                                size: 35, color: Colors.white)
                            : null,
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    technicianName.isNotEmpty ? technicianName : 'Menu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (technicianCode.isNotEmpty)
                    Text(
                      'Code: $technicianCode',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            MenuButton(
              icon: Icons.person,
              label: 'My Profile',
              color: Colors.blue[700]!,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
                // Refresh profile picture after returning from profile screen
                await _loadUserData();
              },
            ),
            MenuButton(
              icon: Icons.event_available,
              label: 'Leave Apply',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LeaveApplyScreen()),
                );
              },
            ),
            MenuButton(
              icon: Icons.receipt_long,
              label: 'Today Expense',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExpenseScreen()),
                );
              },
            ),
            MenuButton(
              icon: Icons.speed,
              label: 'Start Kilometer',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const KilometerScreen(isStart: true)),
                );
              },
            ),
            MenuButton(
              icon: Icons.location_on,
              label: 'End Kilometer',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const KilometerScreen(isStart: false)),
                );
              },
            ),
            MenuButton(
              icon: Icons.science,
              label: 'Chemical In',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChemicalScreen(isIn: true)),
                );
              },
            ),
            MenuButton(
              icon: Icons.science_outlined,
              label: 'Chemical Out',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChemicalScreen(isIn: false)),
                );
              },
            ),
            MenuButton(
              icon: Icons.assignment,
              label: 'Advance Apply',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdvanceApplyScreen()),
                );
              },
            ),
            MenuButton(
              icon: Icons.account_balance_wallet,
              label: 'Submit Cash',
              color: Colors.green[700]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CashSubmissionScreen()),
                );
              },
            ),
            MenuButton(
              icon: Icons.business,
              label: 'Branches',
              color: Colors.blue[700]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BranchesScreen()),
                );
              },
            ),
            MenuButton(
              icon: Icons.help,
              label: 'HELP',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            MenuButton(
              icon: Icons.logout,
              label: 'Logout',
              color: Colors.red[700]!,
              onTap: () {
                _showLogoutDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
