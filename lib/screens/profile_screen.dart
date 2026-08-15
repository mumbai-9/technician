import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../utils/neumorphic_style.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String code = '';
  String userId = '';
  String email = '';
  String phone = '';
  String city = '';
  String state = '';
  String address = '';
  String myReference = '';
  String? profilePictureUrl;
  int? dbId;
  bool isLoading = true;
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Advance balance
  double monthlyBudget = 0;
  double usedAmount = 0;
  double remainingBalance = 0;
  String trackingMonth = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // First get basic auth data for user_id
      final authData = await AuthService.getUserData();
      final userIdValue = authData['user_id'] ?? '';

      if (userIdValue.isEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Fetch full profile from API using the user_id
      final profileResponse = await ApiService.getProfile(userIdValue);

      if (!mounted) return;

      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final data = profileResponse['data'];
        setState(() {
          dbId = data['id'] ?? authData['db_id']; // Use API id, fallback to auth db_id
          name = data['name'] ?? '';
          code = data['code'] ?? '';
          userId = data['user_id'] ?? '';
          email = data['email'] ?? '';
          phone = data['phone'] ?? '';
          city = data['city'] ?? '';
          state = data['state'] ?? '';
          address = data['address'] ?? '';
          myReference = data['my_reference'] ?? '';
          profilePictureUrl = data['profile_picture'];

          // Load advance balance
          if (data['advance_balance'] != null) {
            final advanceBalance = data['advance_balance'];
            monthlyBudget = (advanceBalance['monthly_budget'] ?? 0).toDouble();
            usedAmount = (advanceBalance['used_amount'] ?? 0).toDouble();
            remainingBalance =
                (advanceBalance['remaining_balance'] ?? 0).toDouble();
            trackingMonth = advanceBalance['tracking_month'] ?? '';
          }

          isLoading = false;
        });
      } else {
        // Fallback to auth data if API fails
        final userData = authData;
        setState(() {
          name = userData['name'] ?? '';
          code = userData['code'] ?? '';
          userId = userData['user_id'] ?? '';
          email = userData['email'] ?? '';
          phone = userData['phone'] ?? '';
          city = userData['city'] ?? '';
          state = userData['state'] ?? '';
          address = userData['address'] ?? '';
          myReference = userData['my_reference'] ?? '';
          dbId = userData['db_id'];
          profilePictureUrl = userData['profile_picture'];
          isLoading = false;
        });

        debugPrint('Failed to load full profile: ${profileResponse['message'] ?? "Unknown error"}');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading profile: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Validate technician ID before attempting upload
      if (dbId == null || dbId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Technician ID is invalid. Please refresh and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        debugPrint('❌ Invalid technician ID: $dbId');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,  // Reduce max width for smaller file
        maxHeight: 600, // Reduce max height for smaller file
        imageQuality: 70, // Reduce quality for smaller file size
      );

      if (image == null) return;

      setState(() {
        isUploading = true;
      });

      // Read image bytes using the cross-platform XFile API.
      // Using dart:io File can trigger Unsupported operation errors on some runtimes.
      final bytes = await image.readAsBytes();

      debugPrint('Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');

      // Check image size before encoding
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size too large (max 5MB). Please select a smaller image.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      debugPrint('Base64 size: ${(base64Image.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('Uploading to: /technician/profile/upload-picture');

      // Upload to server
      final result = await ApiService.uploadProfilePicture(
        technicianId: dbId!,
        base64Image: base64Image,
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      if (result['success'] == true) {
        // Update local profile picture URL
        setState(() {
          profilePictureUrl = result['data']['profile_picture_url'] ??
              result['data']['profile_picture'];
        });

        // Update stored user data
        final userData = await AuthService.getUserData();
        userData['profile_picture'] = profilePictureUrl;
        await AuthService.saveUserData(userData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;

        final errorMessage = result['message'] ?? 'Failed to upload profile picture';
        final errorCode = result['error'] ?? 'unknown';
        
        debugPrint('Upload error: $errorCode - $errorMessage');

        String displayMessage = errorMessage;
        if (errorCode == 'payload_too_large') {
          displayMessage = 'Image is too large. The server rejected it. Try a smaller image.';
        } else if (errorCode == 'timeout') {
          displayMessage = 'Upload took too long. Your image might be too large.';
        } else if (errorCode == 'network_error') {
          displayMessage = 'Network error. Please check your connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      debugPrint('Image upload exception: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: NeumorphicStyle.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 10),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildAdvanceBalanceCard(),
                  const SizedBox(height: 20),
                  _buildContactInfoCard(),
                  const SizedBox(height: 20),
                  _buildAddressInfoCard(),
                  const SizedBox(height: 20),
                  if (myReference.isNotEmpty) _buildReferenceCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAdvanceBalanceCard() {
    final percentage =
        monthlyBudget > 0 ? (usedAmount / monthlyBudget) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Advance Balance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Remaining Balance - Large Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${remainingBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used: ₹${usedAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: monthlyBudget > 0 ? usedAmount / monthlyBudget : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 80 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Budget Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${monthlyBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (trackingMonth.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trackingMonth,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration:
                    NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 60),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profilePictureUrl != null
                      ? NetworkImage(profilePictureUrl!)
                      : null,
                  child: profilePictureUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.blue[700],
                        )
                      : null,
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 20),
            child: Text(
              'Code: $code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.contacts,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.badge,
            label: 'Technician Code',
            value: code.isNotEmpty ? code : 'N/A',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.person_outline,
            label: 'User ID',
            value: userId.isNotEmpty ? userId : 'N/A',
            color: Colors.indigo,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email.isNotEmpty ? email : 'Not provided',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: phone.isNotEmpty ? phone : 'Not provided',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Address Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (city.isNotEmpty)
            ...[
              _buildInfoItem(
                icon: Icons.location_city,
                label: 'City',
                value: city,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
            ],
          if (state.isNotEmpty)
            ...[
              _buildInfoItem(
                icon: Icons.map,
                label: 'State',
                value: state,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
            ],
          if (address.isNotEmpty)
            _buildInfoItem(
              icon: Icons.apartment,
              label: 'Address',
              value: address,
              color: Colors.deepOrange,
            )
          else
            _buildInfoItem(
              icon: Icons.apartment,
              label: 'Address',
              value: 'Not provided',
              color: Colors.deepOrange,
            ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add,
                  color: Colors.red[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'My Reference',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.person_pin,
            label: 'Reference',
            value: myReference,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color color = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
