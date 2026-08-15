import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';

class KilometerScreen extends StatefulWidget {
  final bool isStart;
  const KilometerScreen({super.key, required this.isStart});

  @override
  State<KilometerScreen> createState() => _KilometerScreenState();
}

class _KilometerScreenState extends State<KilometerScreen> {
  final TextEditingController kmController = TextEditingController();
  String? userId;
  bool isLoading = false;
  bool isLoadingLocation = false;
  String currentLocation = 'Fetching location...';
  double? latitude;
  double? longitude;
  List<dynamic> history = [];
  Map<String, dynamic>? todayRecord;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    if (userId != null) {
      _fetchKilometerRecords();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
      currentLocation = 'Fetching location...';
    });

    try {
      print('🌍 Checking location service...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          currentLocation = 'Location service disabled';
          isLoadingLocation = false;
        });
        return;
      }

      print('🔐 Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentLocation = 'Location permission denied';
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          currentLocation = 'Location permission permanently denied';
          isLoadingLocation = false;
        });
        return;
      }

      print('📍 Getting position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Position: ${position.latitude}, ${position.longitude}');

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      // Get address from coordinates
      try {
        print('🏠 Getting address...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address += '${place.street!}, ';
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address += '${place.locality!}, ';
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            address += place.administrativeArea!;
          }

          setState(() {
            currentLocation = address.isNotEmpty ? address : 'Location found';
            isLoadingLocation = false;
          });
          print('✅ Address: $address');
        } else {
          setState(() {
            currentLocation =
                'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            isLoadingLocation = false;
          });
        }
      } catch (e) {
        print('❌ Error getting address: $e');
        setState(() {
          currentLocation =
              'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        currentLocation = 'Unable to get location';
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _fetchKilometerRecords() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getKilometerRecords(
        userId: userId!,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      if (response['success'] == true) {
        setState(() {
          todayRecord = response['today'];
          history = response['history'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();

      if (cameraStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Camera permission is required to take photos')),
          );
        }
        return;
      }

      if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Camera permission permanently denied. Please enable it in settings.'),
              duration: Duration(seconds: 3),
            ),
          );
          // Open app settings
          await openAppSettings();
        }
        return;
      }

      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured successfully!'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if already recorded
    bool alreadyRecorded = false;
    if (todayRecord != null) {
      if (widget.isStart && todayRecord!['start'] != null) {
        alreadyRecorded = true;
      } else if (!widget.isStart && todayRecord!['end'] != null) {
        alreadyRecorded = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStart ? 'Start Kilometer' : 'End Kilometer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchKilometerRecords();
              _getCurrentLocation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildCurrentInfo(),
                      const SizedBox(height: 24),
                      if (alreadyRecorded)
                        _buildAlreadyRecorded()
                      else
                        _buildKmForm(),
                      const SizedBox(height: 24),
                      if (history.isNotEmpty) _buildHistory(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Icon(
            widget.isStart
                ? Icons.play_circle_outline
                : Icons.stop_circle_outlined,
            size: 64,
            color: widget.isStart ? Colors.green[600] : Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isStart ? 'Start Your Day' : 'End Your Day',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isLoadingLocation
                      ? Icons.location_searching
                      : Icons.location_on,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentLocation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyRecorded() {
    final record = widget.isStart ? todayRecord!['start'] : todayRecord!['end'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Already Recorded',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reading:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${record['reading']} KM',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Time:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      record['recorded_at'] ?? '--:--',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (record['address'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record['address'],
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKmForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isStart ? 'Enter Starting KM' : 'Enter Ending KM',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
            child: TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Kilometer Reading',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.speed),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Photo Upload Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Odometer Photo ${_selectedImage != null ? '✓' : '(Optional)'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedImage != null
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retake'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Remove'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: widget.isStart ? Colors.green[700]! : Colors.red[700]!,
              borderRadius: 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoadingLocation ? null : _submitKm,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    widget.isStart ? 'START DAY' : 'END DAY',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
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

  Widget _buildHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...history.map((record) => _buildHistoryItem(record)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(dynamic record) {
    final date = DateFormatter.formatDate(record['date']);
    final startReading = record['start_reading']?.toString() ?? '0';
    final endReading = record['end_reading']?.toString() ?? '0';
    final distance = record['distance']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Start: $startReading KM',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text('End: $endReading KM',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(
                'Total: $distance KM',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitKm() async {
    if (kmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter kilometer reading')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Convert image to base64 if selected
      String? photoBase64;
      if (_selectedImage != null) {
        photoBase64 = await _convertImageToBase64();
      }

      // Record kilometer reading
      final response = await ApiService.recordKilometer(
        userId: userId!,
        type: widget.isStart ? 'start' : 'end',
        reading: double.parse(kmController.text),
        latitude: latitude,
        longitude: longitude,
        address: currentLocation != 'Fetching location...' &&
                currentLocation != 'Unable to get location'
            ? currentLocation
            : null,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        time: DateFormat('HH:mm:ss').format(DateTime.now()),
        photoBase64: photoBase64,
      );

      if (response['success'] != true) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Failed to record kilometer')),
          );
        }
        return;
      }

      // Now start or end the shift
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Technician ID not found')),
          );
        }
        return;
      }

      Map<String, dynamic> shiftResult;
      if (widget.isStart) {
        // Start shift
        shiftResult = await ApiService.startShift(
          technicianId: technicianId,
          kilometerPhoto: _selectedImage ?? File(''),
          latitude: latitude ?? 0,
          longitude: longitude ?? 0,
        );
      } else {
        // End shift
        shiftResult = await ApiService.endShift(
          technicianId: technicianId,
          kilometerPhoto: _selectedImage ?? File(''),
          latitude: latitude ?? 0,
          longitude: longitude ?? 0,
        );
      }

      setState(() {
        isLoading = false;
      });

      if (shiftResult['success'] == true) {
        if (mounted) {
          if (widget.isStart) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shift started successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            // Show shift end summary dialog
            final hours = shiftResult['total_hours_worked'] ?? 0;
            final status = shiftResult['calculated_status'] ?? '';
            final notes = shiftResult['notes'] ?? '';

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Icon(
                      status == 'present'
                          ? Icons.check_circle
                          : status == 'half_day'
                              ? Icons.timelapse
                              : Icons.cancel,
                      color: status == 'present'
                          ? Colors.green
                          : status == 'half_day'
                              ? Colors.orange
                              : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text('Shift Ended'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Hours: ${hours.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notes,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Return to home
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shiftResult['message'] ??
                  'Failed to ${widget.isStart ? "start" : "end"} shift'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    kmController.dispose();
    super.dispose();
  }
}
