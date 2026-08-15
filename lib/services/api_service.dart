import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class ApiService {
  // API base URL is now managed in api_config.dart
  // Change the environment there to switch between emulator/physical device/production
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, dynamic> _parseResponseBody(http.Response response) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return {
        'success': false,
        'message': 'Server returned an empty response (Status: ${response.statusCode}).',
      };
    }

    if (body.startsWith('<') || body.contains('<!DOCTYPE') || body.contains('<html')) {
      String errorMsg = 'Server returned HTML instead of JSON (Status: ${response.statusCode}).';

      if (response.statusCode == 404) {
        errorMsg =
            'API endpoint not found (404). Please check if the backend route is available.';
      } else if (response.statusCode == 500) {
        errorMsg = 'Server error (500). Please check the Laravel logs.';
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid JSON response from server. Response: ${body.substring(0, body.length > 120 ? 120 : body.length)}',
      };
    }
  }

  /// Technician Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/technician/login');

    try {
      print('=== API Login Request (Technician) ===');
      print('URL: $url');
      print('Email: $email');
      print('Base URL: $baseUrl');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print(
          'Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      return _parseResponseBody(response);
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
      return {
        'success': false,
        'message':
            'Connection timeout. Please check:\n1. Backend server is running\n2. IP address is correct\n3. Phone and laptop on same WiFi',
      };
    } on SocketException catch (e) {
      print('Socket Error: $e');
      return {
        'success': false,
        'message':
            'Cannot connect to server. Please check:\n1. Backend server is running (START_BACKEND_SERVER.bat)\n2. IP address: $baseUrl\n3. Firewall settings',
      };
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Technician Profile
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final url = Uri.parse('$baseUrl/technician/profile');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Upload Profile Picture
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required int technicianId,
    required String base64Image,
  }) async {
    final url = Uri.parse('$baseUrl/technician/profile/upload-picture');

    try {
      print('=== Uploading Profile Picture ===');
      print('URL: $url');
      print('Technician ID: $technicianId');
      print('Image Size: ${base64Image.length} bytes');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'technician_id': technicianId,
          'profile_picture': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timeout - file may be too large');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 413) {
        return {
          'success': false,
          'message': 'File size too large. Please select a smaller image.',
          'error': 'payload_too_large',
        };
      }

      return _parseResponseBody(response);
    } on TimeoutException catch (e) {
      print('Upload Timeout: $e');
      return {
        'success': false,
        'message': 'Upload timeout. File may be too large or connection is slow.',
        'error': 'timeout',
      };
    } catch (e) {
      print('Upload Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': 'network_error',
      };
    }
  }

  /// Update Technician Profile
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
  }) async {
    final url = Uri.parse('$baseUrl/technician/profile/update');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get All Branches
  static Future<Map<String, dynamic>> getBranches() async {
    final url = Uri.parse('$baseUrl/technician/branches');

    try {
      final response = await http.get(url);
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Branch Details
  static Future<Map<String, dynamic>> getBranchDetails(int branchId) async {
    final url = Uri.parse('$baseUrl/technician/branches/$branchId');

    try {
      final response = await http.get(url);
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get My Jobs (max 2 active jobs)
  static Future<Map<String, dynamic>> getMyJobs(int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/jobs');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'technician_id': technicianId}),
      );

      return _parseResponseBody(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Tomorrow's Jobs (read-only preview)
  static Future<Map<String, dynamic>> getTomorrowJobs(int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/jobs/tomorrow');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'technician_id': technicianId}),
      );

      return _parseResponseBody(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Grab Job - Technician accepts the job
  static Future<Map<String, dynamic>> grabJob(
      int jobId, int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/jobs/grab');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Start Job - Record job start time
  static Future<Map<String, dynamic>> startJob(
      int jobId, int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/jobs/start');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Close Job - Mark job as completed for recurring jobs with paid status
  static Future<Map<String, dynamic>> closeJob(
      int jobId, int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/jobs/close');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Update Job Status
  static Future<Map<String, dynamic>> updateJobStatus(
      int jobId, String status) async {
    final url = Uri.parse('$baseUrl/technician/jobs/update-status');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'status': status,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Update Payment (Legacy - kept for backward compatibility)
  static Future<Map<String, dynamic>> updatePayment({
    required int jobId,
    required int technicianId,
    required String paymentMode,
    required double paidAmount,
    XFile? paymentProofImage,
    String? techNotes,
    String? paymentStatus, // explicit status override ('paid' | 'partial' | null)
    String? paymentAccount,
  }) async {
    // Use new carry forward payment processing
    return processJobPayment(
      jobId: jobId,
      technicianId: technicianId,
      paymentMode: paymentMode,
      paidAmount: paidAmount,
      paymentProofImage: paymentProofImage,
      techNotes: techNotes,
      paymentStatus: paymentStatus,
      paymentAccount: paymentAccount,
    );
  }

  /// Process Job Payment with Carry Forward Support
  static Future<Map<String, dynamic>> processJobPayment({
    required int jobId,
    required int technicianId,
    required String paymentMode,
    required double paidAmount,
    XFile? paymentProofImage,
    String? techNotes,
    String? paymentStatus, // explicit status override ('paid' | 'partial' | null)
    String? paymentAccount,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/$jobId/process-payment');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add form fields
      request.fields['technician_id'] = technicianId.toString();
      request.fields['payment_mode'] = paymentMode;
      request.fields['paid_amount'] = paidAmount.toString();
      if (paymentAccount != null && paymentAccount.isNotEmpty) {
        request.fields['payment_account'] = paymentAccount;
      }

      // Explicitly send payment_status so backend doesn't have to infer it.
      // This prevents any race condition where updateJobStatus resets the status.
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        request.fields['payment_status'] = paymentStatus;
      }

      // Add tech notes if provided
      if (techNotes != null && techNotes.isNotEmpty) {
        request.fields['tech_notes'] = techNotes;
      }

      // Add payment proof image if available
      if (paymentProofImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'payment_proof',
            paymentProofImage.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Payment Summary with Carry Forward Data
  static Future<Map<String, dynamic>> getPaymentSummary({
    required int jobId,
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/$jobId/payment-summary?technician_id=$technicianId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Jobs with Carry Forward Status
  static Future<Map<String, dynamic>> getJobsWithCarryForward({
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs-with-carry-forward?technician_id=$technicianId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Schedule Revisit
  static Future<Map<String, dynamic>> scheduleRevisit({
    required int jobId,
    required int technicianId,
    required String revisitDate,
    required String revisitTime,
    String? reason,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/schedule-revisit');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
          'revisit_date': revisitDate,
          'revisit_time': revisitTime,
          'reason': reason,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Complete and Reschedule Job
  static Future<Map<String, dynamic>> completeAndReschedule({
    required int jobId,
    required int technicianId,
    required String rescheduleDate,
    required String rescheduleTime,
    String? rescheduleReason,
    required String paymentMode,
    required double paidAmount,
    String? paymentProof,
    String? paymentAccount,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/complete-and-reschedule');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
          'reschedule_date': rescheduleDate,
          'reschedule_time': rescheduleTime,
          'reschedule_reason': rescheduleReason,
          'payment_mode': paymentMode,
          'payment_account': paymentAccount,
          'paid_amount': paidAmount,
          'payment_proof': paymentProof,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Upload Job Photos
  static Future<Map<String, dynamic>> uploadJobPhotos({
    required int jobId,
    required int technicianId,
    required List<dynamic> beforePhotos,
    required List<dynamic> afterPhotos,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/upload-photos');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add fields
      request.fields['job_id'] = jobId.toString();
      request.fields['technician_id'] = technicianId.toString();

      // Add before photos
      for (var i = 0; i < beforePhotos.length; i++) {
        final photo = beforePhotos[i];
        request.files.add(
          await http.MultipartFile.fromPath(
            'before_photos[]',
            photo.path,
          ),
        );
      }

      // Add after photos
      for (var i = 0; i < afterPhotos.length; i++) {
        final photo = afterPhotos[i];
        request.files.add(
          await http.MultipartFile.fromPath(
            'after_photos[]',
            photo.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      return jsonDecode(responseBody);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Upload Customer Signature
  static Future<Map<String, dynamic>> uploadSignature({
    required int jobId,
    required int technicianId,
    required String signature,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/upload-signature');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
          'signature': signature,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Add Add-On Services to Job
  static Future<Map<String, dynamic>> addAddonServices({
    required int jobId,
    required int technicianId,
    required List<Map<String, dynamic>> addonServices,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/add-addon-services');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': jobId,
          'technician_id': technicianId,
          'addon_services': addonServices,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Dashboard Stats
  static Future<Map<String, dynamic>> getStats(int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/stats');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Mark Attendance (Check In/Out)
  static Future<Map<String, dynamic>> markAttendance({
    required int technicianId,
    required String type, // 'check_in' or 'check_out'
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/technician/attendance/mark');

    try {
      final body = {
        'technician_id': technicianId,
        'type': type,
      };

      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (address != null) body['address'] = address;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Attendance History
  static Future<Map<String, dynamic>> getAttendance({
    required int technicianId,
    int? month,
    int? year,
  }) async {
    final url = Uri.parse('$baseUrl/technician/attendance/get');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Submit Leave Request
  static Future<Map<String, dynamic>> submitLeaveRequest({
    required int technicianId,
    required String startDate,
    required String endDate,
    required String leaveType,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/technician/leave/submit');

    print('=== SUBMITTING LEAVE REQUEST ===');
    print('URL: $url');
    print('Technician ID: $technicianId');
    print('Start Date: $startDate');
    print('End Date: $endDate');
    print('Leave Type: $leaveType');
    print('Reason: $reason');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
          'start_date': startDate,
          'end_date': endDate,
          'leave_type': leaveType,
          'reason': reason,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') == true) {
        print('ERROR: Received HTML instead of JSON');
        print('This usually means:');
        print('1. Wrong URL (404 Not Found)');
        print('2. Server error (500 Internal Server Error)');
        print('3. Laravel not running');

        return {
          'success': false,
          'message':
              'Server error: Received HTML instead of JSON. Status: ${response.statusCode}',
          'error_details':
              'Check if Laravel server is running and URL is correct',
        };
      }

      // Try to parse JSON
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('ERROR: Failed to parse JSON: $e');
        return {
          'success': false,
          'message': 'Invalid response from server',
          'error_details': response.body.substring(0, 200), // First 200 chars
        };
      }
    } catch (e) {
      print('ERROR: Network exception: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error_details': 'Check your internet connection and server URL',
      };
    }
  }

  /// Get Leave Requests
  static Future<Map<String, dynamic>> getLeaveRequests({
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/leave/requests');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Check if technician is on leave today
  static Future<Map<String, dynamic>> checkLeaveStatus({
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/leave/check-status');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Add Expense
  static Future<Map<String, dynamic>> addExpense({
    required String userId,
    required String category,
    required double amount,
    required String description,
    required String date,
    String? receiptPhoto,
  }) async {
    final url = Uri.parse('$baseUrl/technician/expense/add');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'category': category,
          'amount': amount,
          'description': description,
          'date': date,
          if (receiptPhoto != null) 'receipt_photo': receiptPhoto,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Expenses
  static Future<Map<String, dynamic>> getExpenses({
    required String userId,
    String? date,
  }) async {
    final url = Uri.parse('$baseUrl/technician/expense/get');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (date != null) 'date': date,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Record Kilometer
  static Future<Map<String, dynamic>> recordKilometer({
    required String userId,
    required String type, // 'start' or 'end'
    required double reading,
    double? latitude,
    double? longitude,
    String? address,
    required String date,
    required String time,
    String? photoBase64, // base64 encoded photo
  }) async {
    final url = Uri.parse('$baseUrl/technician/kilometer/record');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'reading': reading,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
          'date': date,
          'time': time,
          if (photoBase64 != null) 'photo': photoBase64,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Kilometer Records
  static Future<Map<String, dynamic>> getKilometerRecords({
    required String userId,
    String? date,
  }) async {
    final url = Uri.parse('$baseUrl/technician/kilometer/get');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (date != null) 'date': date,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Active Chemicals
  static Future<List<dynamic>> getActiveChemicals() async {
    final url = Uri.parse('$baseUrl/chemicals/active');

    try {
      final response = await http.get(url);
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  /// Record Chemical Transaction
  static Future<Map<String, dynamic>> recordChemicalTransaction({
    required String userId,
    required int chemicalId,
    required String type, // 'in' or 'out'
    required double quantity,
    required String date,
    required String time,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/technician/chemical/transaction');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'chemical_id': chemicalId,
          'type': type,
          'quantity': quantity,
          'date': date,
          'time': time,
          if (notes != null) 'notes': notes,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Chemical Inventory
  static Future<Map<String, dynamic>> getChemicalInventory({
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/chemical/inventory');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Submit Advance Request
  static Future<Map<String, dynamic>> submitAdvanceRequest({
    required String userId,
    required double amount,
    required String reason,
    required String requestDate,
  }) async {
    final url = Uri.parse('$baseUrl/technician/advance/submit');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'reason': reason,
          'request_date': requestDate,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Advance Requests
  static Future<Map<String, dynamic>> getAdvanceRequests({
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/advance/requests');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Payment QR Code for Technician
  static Future<Map<String, dynamic>> getPaymentQrCode(int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/payment/qr-code');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Cash Collectors by Technician's Branch
  static Future<Map<String, dynamic>> getCashCollectorsByBranch(
      int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/cash/collectors');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Pending Cash Submissions
  static Future<Map<String, dynamic>> getPendingCashSubmissions(
      int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/cash/pending');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Submit Cash to Cash Collector
  static Future<Map<String, dynamic>> submitCashToCollector({
    required int technicianId,
    required List<int> jobIds,
    required int cashCollectorId,
    String? notes,
  }) async {
    final url = Uri.parse('$baseUrl/technician/cash/submit');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
          'job_ids': jobIds,
          'cash_collector_id': cashCollectorId,
          'notes': notes,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Cash Collection Summary
  static Future<Map<String, dynamic>> getCashCollectionSummary({
    required int technicianId,
    String? date,
  }) async {
    final url = Uri.parse('$baseUrl/technician/cash/summary');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
          'date': date,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Start Shift with kilometer photo
  static Future<Map<String, dynamic>> startShift({
    required int technicianId,
    required File kilometerPhoto,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/technician/shift/start');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add fields
      request.fields['technician_id'] = technicianId.toString();
      request.fields['start_latitude'] = latitude.toString();
      request.fields['start_longitude'] = longitude.toString();
      if (address != null) {
        request.fields['address'] = address;
      }

      // Add kilometer photo
      request.files.add(
        await http.MultipartFile.fromPath(
          'start_kilometer_photo',
          kilometerPhoto.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// End Shift with kilometer photo
  static Future<Map<String, dynamic>> endShift({
    required int technicianId,
    required File kilometerPhoto,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/technician/shift/end');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add fields
      request.fields['technician_id'] = technicianId.toString();
      request.fields['end_latitude'] = latitude.toString();
      request.fields['end_longitude'] = longitude.toString();
      if (address != null) {
        request.fields['address'] = address;
      }

      // Add kilometer photo
      request.files.add(
        await http.MultipartFile.fromPath(
          'end_kilometer_photo',
          kilometerPhoto.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Today's Working Hours
  static Future<Map<String, dynamic>> getTodayWorkingHours(
      int technicianId) async {
    final url = Uri.parse('$baseUrl/technician/shift/today');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get Monthly Attendance
  static Future<Map<String, dynamic>> getMonthlyAttendance({
    required int technicianId,
    String? month,
  }) async {
    final url = Uri.parse('$baseUrl/technician/shift/monthly');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
          'month': month,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Download Job Invoice (PDF)
  static Future<Map<String, dynamic>> downloadJobInvoice({
    required int jobId,
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/$jobId/download-invoice');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'download_url': url.toString(),
        };
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// View Job Invoice (for sharing)
  static Future<Map<String, dynamic>> viewJobInvoice({
    required int jobId,
    required int technicianId,
  }) async {
    final url = Uri.parse('$baseUrl/technician/jobs/$jobId/view-invoice');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technician_id': technicianId,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'view_url': url.toString(),
        };
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
