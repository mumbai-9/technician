import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/job_model.dart';
import '../models/job.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BeforeAfterPhotosScreen extends StatefulWidget {
  final JobModel job;
  final Job? jobData;

  const BeforeAfterPhotosScreen({
    super.key,
    required this.job,
    this.jobData,
  });

  @override
  State<BeforeAfterPhotosScreen> createState() =>
      _BeforeAfterPhotosScreenState();
}

class _BeforeAfterPhotosScreenState extends State<BeforeAfterPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> beforePhotos = [];
  List<XFile> afterPhotos = [];
  bool isUploading = false;

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and storage permissions are required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _pickImage(bool isBefore) async {
    try {
      await _requestPermissions();

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, // Only camera, no gallery
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isBefore) {
            beforePhotos.add(image);
          } else {
            afterPhotos.add(image);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(bool isBefore, int index) {
    setState(() {
      if (isBefore) {
        beforePhotos.removeAt(index);
      } else {
        afterPhotos.removeAt(index);
      }
    });
  }

  Future<void> _uploadPhotos() async {
    if (beforePhotos.isEmpty && afterPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      final result = await ApiService.uploadJobPhotos(
        jobId: jobId,
        technicianId: technicianId,
        beforePhotos: beforePhotos,
        afterPhotos: afterPhotos,
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to upload photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Before & After Photos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfo(),
                    const SizedBox(height: 24),
                    _buildPhotoSection(
                      title: 'BEFORE SERVICE PHOTOS',
                      photos: beforePhotos,
                      isBefore: true,
                      color: Colors.orange[700]!,
                    ),
                    const SizedBox(height: 24),
                    _buildPhotoSection(
                      title: 'AFTER SERVICE PHOTOS',
                      photos: afterPhotos,
                      isBefore: false,
                      color: Colors.green[700]!,
                    ),
                  ],
                ),
              ),
            ),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.job.service,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required List<XFile> photos,
    required bool isBefore,
    required Color color,
  }) {
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
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${photos.length} photo${photos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (photos.isEmpty)
            _buildEmptyState(isBefore, color)
          else
            _buildPhotoGrid(photos, isBefore),
          const SizedBox(height: 16),
          _buildAddPhotoButton(isBefore, color),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isBefore, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            'No photos added yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<XFile> photos, bool isBefore) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photos[index].path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removePhoto(isBefore, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPhotoButton(bool isBefore, Color color) {
    return GestureDetector(
      onTap: () => _pickImage(isBefore),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'Take Photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final hasPhotos = beforePhotos.isNotEmpty || afterPhotos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        decoration: NeumorphicStyle.coloredNeumorphicDecoration(
          color: hasPhotos ? Colors.blue[700]! : Colors.grey[400]!,
          borderRadius: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isUploading || !hasPhotos) ? null : _uploadPhotos,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          hasPhotos ? 'UPLOAD PHOTOS' : 'TAKE PHOTOS FIRST',
                          style: const TextStyle(
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
    );
  }
}
