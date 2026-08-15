import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/job_model.dart';
import '../models/job.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final JobModel job;
  final Job? jobData;

  const PaymentScreen({super.key, required this.job, this.jobData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentType = 'cash';
  bool isSaving = false;
  bool isLoadingQrCode = false;

  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController paymentAccountController = TextEditingController();
  final TextEditingController techNotesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  double totalAmount = 0;
  double paidAmount = 0;
  double pendingAmount = 0;
  String paymentStatus = 'pending';

  // QR Code data
  String? qrCodeImageUrl;
  String? qrCodePaymentName;
  String? qrCodeUpiId;
  bool qrCodeAvailable = false;

  // Payment proof image
  XFile? paymentProofImage;
  bool isCapturingImage = false;

  // Schedule Revisit
  bool isSchedulingRevisit = false;
  DateTime? selectedRevisitDate;
  TimeOfDay? selectedRevisitTime;
  final TextEditingController revisitReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
    _loadQrCodeData();
  }

  void _loadPaymentData() async {
    // First load basic data from job
    if (widget.jobData != null) {
      setState(() {
        // Use total_amount which includes base amount + addon services
        totalAmount = widget.jobData!.totalAmount > 0
            ? widget.jobData!.totalAmount
            : (widget.jobData!.amount ?? 0);

        paidAmount = widget.jobData!.paidAmount;
        pendingAmount = widget.jobData!.pendingAmount;
        paymentStatus = widget.jobData!.paymentStatus;
        selectedPaymentType = widget.jobData!.paymentMode;
        paymentAccountController.text = widget.jobData!.paymentAccount ?? '';

        // If total amount is 0, calculate from job model + addon services
        if (totalAmount == 0) {
          final baseAmount = widget.job.amount;
          final addonAmount = widget.jobData!.addonAmount;
          totalAmount = baseAmount + addonAmount;
          pendingAmount = totalAmount - paidAmount;
        }

        // For recurring jobs that are already paid, don't show payment collection
        if (widget.jobData!.isRecurringSeries &&
            !widget.jobData!.showPaymentCollection) {
          // Job is already paid, show 0 pending
          pendingAmount = 0;
          paymentStatus = 'paid';
          paidAmountController.text = '0';
        } else {
          // Set pending amount in text field by default
          if (pendingAmount > 0) {
            paidAmountController.text = pendingAmount.toStringAsFixed(0);
          } else if (totalAmount > 0) {
            paidAmountController.text = totalAmount.toStringAsFixed(0);
          }
        }
      });
    } else {
      setState(() {
        totalAmount = widget.job.amount;
        pendingAmount = totalAmount;
        if (totalAmount > 0) {
          paidAmountController.text = totalAmount.toStringAsFixed(0);
        }
      });
    }

    // For recurring jobs, get updated payment summary from API
    if (widget.jobData?.isRecurringSeries == true ||
        widget.jobData?.hasCarryForward == true) {
      await _loadPaymentSummaryFromAPI();
    }
  }

  Future<void> _loadPaymentSummaryFromAPI() async {
    try {
      // Get technician ID from stored data
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        debugPrint('No technician ID available for payment summary');
        return;
      }

      final result = await ApiService.getPaymentSummary(
        jobId: int.parse(widget.job.id),
        technicianId: technicianId,
      );

      if (result['success'] == true && result['data'] != null) {
        final summaryData = result['data'];

        setState(() {
          totalAmount = (summaryData['total_amount'] ?? 0.0).toDouble();
          paidAmount = (summaryData['total_paid'] ?? 0.0).toDouble();
          pendingAmount = (summaryData['pending_amount'] ?? 0.0).toDouble();

          // Update payment collection visibility
          final showPaymentOption = summaryData['show_payment_option'] ?? true;
          if (!showPaymentOption && pendingAmount == 0) {
            paymentStatus = 'paid';
            paidAmountController.text = '0';
          } else if (pendingAmount > 0) {
            paidAmountController.text = pendingAmount.toStringAsFixed(0);
          }
        });

        debugPrint(
            'Payment summary loaded from API: Total: ₹$totalAmount, Paid: ₹$paidAmount, Pending: ₹$pendingAmount');
      }
    } catch (e) {
      debugPrint('Error loading payment summary: $e');
      // Continue with existing data if API fails
    }
  }

  Future<void> _loadQrCodeData() async {
    try {
      setState(() {
        isLoadingQrCode = true;
      });

      // Get technician ID from stored data - use db_id key
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      debugPrint('=== Loading QR Code ===');
      debugPrint('Technician ID (from db_id): $technicianId');

      if (technicianId == 0) {
        debugPrint('No technician ID available for QR code');
        setState(() {
          isLoadingQrCode = false;
          qrCodeAvailable = false;
        });
        return;
      }

      final result = await ApiService.getPaymentQrCode(technicianId);

      debugPrint('QR Code API Response: $result');

      if (result['success'] == true && result['data'] != null) {
        final qrData = result['data'];
        setState(() {
          qrCodeImageUrl = qrData['qr_code_url']; // Backend returns full URL
          qrCodePaymentName = qrData['payment_name'];
          qrCodeUpiId = qrData['upi_id'];
          qrCodeAvailable = true;
          if (selectedPaymentType == 'upi' && paymentAccountController.text.isEmpty && qrCodeUpiId != null) {
            paymentAccountController.text = qrCodeUpiId!;
          }
          isLoadingQrCode = false;
        });
        debugPrint('QR Code loaded successfully: $qrCodeImageUrl');
      } else {
        setState(() {
          isLoadingQrCode = false;
          qrCodeAvailable = false;
        });
        debugPrint('QR code not available: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        isLoadingQrCode = false;
        qrCodeAvailable = false;
      });
      debugPrint('Error loading QR code: $e');
    }
  }

  @override
  void dispose() {
    paidAmountController.dispose();
    paymentAccountController.dispose();
    techNotesController.dispose();
    revisitReasonController.dispose();
    super.dispose();
  }

  Future<void> _capturePaymentProof() async {
    try {
      setState(() {
        isCapturingImage = true;
      });

      // Show options: Camera or Gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        setState(() {
          isCapturingImage = false;
        });
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          paymentProofImage = image;
          isCapturingImage = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment proof captured successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          isCapturingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        isCapturingImage = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePaymentProof() {
    setState(() {
      paymentProofImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment proof removed'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _viewPaymentProof() {
    if (paymentProofImage == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Proof'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    Navigator.pop(context);
                    _removePaymentProof();
                  },
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.file(
                  File(paymentProofImage!.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    final enteredAmount = double.tryParse(paidAmountController.text) ?? 0;

    // Allow 0 rupees payment, but not negative amounts
    if (enteredAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount cannot be negative'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If total amount is 0, use entered amount as total
    if (totalAmount == 0) {
      totalAmount = enteredAmount;
      pendingAmount = enteredAmount;
    }

    if (enteredAmount > pendingAmount && pendingAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed pending amount (₹${pendingAmount.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      // Validate account/UPI details for non-cash payments
      String? paymentAccount = paymentAccountController.text.trim();
      if (selectedPaymentType == 'upi' && paymentAccount.isEmpty && qrCodeUpiId != null) {
        paymentAccount = qrCodeUpiId!;
      }

      if (selectedPaymentType != 'cash' && paymentAccount.isEmpty) {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter payment destination for the selected payment type'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Calculate new paid amount (add to existing)
      final newPaidAmount = paidAmount + enteredAmount;

      // Determine if this constitutes a full / complete payment.
      // A ₹0 total (warranty/complaint job) is always considered fully paid.
      final isFullPayment =
          totalAmount == 0 || (totalAmount > 0 && newPaidAmount >= totalAmount);

      // -------------------------------------------------------
      // CORRECT FLOW:
      // Step 1 — processJobPayment  → records payment + sets payment_status
      // Step 2 — closeJob           → properly closes the job without
      //                               touching payment_status
      //
      // Do NOT use updateJobStatus('completed') here — that generic endpoint
      // resets payment_status to 'pending' as a side effect on the backend.
      // closeJob is the dedicated endpoint (used by job_detail_screen.dart)
      // that closes the job cleanly.
      // -------------------------------------------------------

      // STEP 1: Record payment and set payment_status
      final paymentResult = await ApiService.updatePayment(
        jobId: jobId,
        technicianId: technicianId,
        paymentMode: selectedPaymentType,
        paidAmount: newPaidAmount,
        paymentProofImage: paymentProofImage,
        techNotes: techNotesController.text.trim().isNotEmpty
            ? techNotesController.text.trim()
            : null,
        paymentAccount: paymentAccount,
        // Explicitly tell the backend whether this is a full payment
        paymentStatus: isFullPayment ? 'paid' : 'partial',
      );

      if (!mounted) return;

      if (paymentResult['success'] != true) {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentResult['message'] ?? 'Failed to save payment',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // STEP 2: Close the job using the dedicated close endpoint
      // (this does NOT reset payment_status, unlike updateJobStatus)
      final closeResult = await ApiService.closeJob(jobId, technicianId);

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      if (closeResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment saved & job completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _showReceiptOptionsDialog();
      } else {
        // Payment saved but close failed — warn but don't block receipt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment saved but failed to close job: ${closeResult['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        // Still show receipt — payment was recorded successfully
        _showReceiptOptionsDialog();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        actions: [
          // Debug info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Branch ID: ${widget.jobData?.branchId ?? "NULL"}',
                        ),
                        const SizedBox(height: 8),
                        Text('QR Available: $qrCodeAvailable'),
                        const SizedBox(height: 8),
                        Text('Loading: $isLoadingQrCode'),
                        const SizedBox(height: 8),
                        Text('QR URL: ${qrCodeImageUrl ?? "NULL"}'),
                        const SizedBox(height: 8),
                        Text('Payment Name: ${qrCodePaymentName ?? "NULL"}'),
                        const SizedBox(height: 8),
                        Text('UPI ID: ${qrCodeUpiId ?? "NULL"}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPaymentSummary(),
                const SizedBox(height: 24),
                _buildPaymentOptions(),
                const SizedBox(height: 24),
                _buildAmountInput(),
                const SizedBox(height: 24),
                _buildTechNotesInput(),
                const SizedBox(height: 24),
                _buildPaymentProofSection(),
                const SizedBox(height: 24),
                if (selectedPaymentType != 'cash') _buildQRSection(),
                if (selectedPaymentType != 'cash') const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 16),
                _buildCompleteAndRescheduleButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Text(
            widget.job.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.job.date,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    // Check if there are addon services
    final hasAddonServices = widget.jobData?.addonServices != null &&
        widget.jobData!.addonServices!.isNotEmpty;
    final baseAmount = widget.jobData?.amount ?? widget.job.amount;
    final isRecurring = widget.jobData?.isRecurringSeries ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          // Recurring job indicator
          if (isRecurring) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Recurring Job ${widget.jobData?.recurringSequence ?? 1}/${widget.jobData?.totalRecurringJobs ?? 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (hasAddonServices) ...[
            _buildSummaryRow('Base Amount:', baseAmount, Colors.blue[700]!),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Show addon services
            ...widget.jobData!.addonServices!.map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '+ ${service['service_name']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Text(
                      '₹${double.parse(service['amount'].toString()).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
          ],
          _buildSummaryRow('Total Amount:', totalAmount, Colors.blue[700]!),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildSummaryRow('Paid Amount:', paidAmount, Colors.green[700]!),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Pending Amount:',
            pendingAmount,
            Colors.orange[700]!,
          ),
          const SizedBox(height: 16),

          // Payment status with recurring job context
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor()),
            ),
            child: Column(
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
                if (isRecurring && paymentStatus == 'paid') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Customer paid in advance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (paymentStatus) {
      case 'paid':
        return Colors.green[700]!;
      case 'partial':
        return Colors.orange[700]!;
      default:
        return Colors.red[700]!;
    }
  }

  String _getStatusText() {
    switch (paymentStatus) {
      case 'paid':
        return 'FULLY PAID';
      case 'partial':
        return 'PARTIALLY PAID';
      default:
        return 'PAYMENT PENDING';
    }
  }

  Widget _buildPaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT PAYMENT TYPE',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          'ACCEPT CASH',
          'cash',
          Colors.green[700]!,
          Icons.money,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'UPI Scan QR',
          'upi',
          Colors.blue[700]!,
          Icons.qr_code_scanner,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'ONLINE / BANK',
          'account',
          Colors.blueGrey[700]!,
          Icons.account_balance,
        ),
        const SizedBox(height: 16),
        if (selectedPaymentType != 'cash') _buildPaymentAccountInput(),
      ],
    );
  }

  Widget _buildPaymentOption(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final isSelected = selectedPaymentType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: NeumorphicStyle.coloredNeumorphicDecoration(
          color: color,
          borderRadius: 12,
          isPressed: isSelected,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  isSelected ? Icon(Icons.check, size: 18, color: color) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAccountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT DESTINATION',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: NeumorphicStyle.neumorphicInsetDecoration(
              borderRadius: 12,
            ),
            child: TextField(
              controller: paymentAccountController,
              keyboardType: TextInputType.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: selectedPaymentType == 'upi'
                    ? 'Enter UPI ID or payment destination'
                    : 'Enter bank/account details',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                prefixIcon: Icon(
                  selectedPaymentType == 'upi'
                      ? Icons.qr_code
                      : Icons.account_balance,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedPaymentType == 'upi'
                ? 'If UPI Scan QR is selected, use the customer payment UPI destination here.'
                : 'Enter the bank or account details used for this payment.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTER AMOUNT TO COLLECT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: NeumorphicStyle.neumorphicInsetDecoration(
              borderRadius: 12,
            ),
            child: TextField(
              controller: paidAmountController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Trigger rebuild to enable/disable save button
                setState(() {});
              },
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: totalAmount > 0
                    ? 'Enter amount'
                    : 'Enter amount (no job amount set)',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.currency_rupee, color: Colors.grey[600]),
                suffixText: 'Rs.',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (pendingAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending: ₹${pendingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    paidAmountController.text = pendingAmount.toStringAsFixed(
                      0,
                    );
                  },
                  child: const Text('Pay Full'),
                ),
              ],
            )
          else
            Text(
              'Enter the amount customer is paying',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTechNotesInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES FOR NEXT TECHNICIAN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add notes that will be visible to the next technician on future visits',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: NeumorphicStyle.neumorphicInsetDecoration(
              borderRadius: 12,
            ),
            child: TextField(
              controller: techNotesController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: 'Enter notes for next technician (optional)...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.note_add, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.camera_alt, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'PAYMENT PROOF',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (paymentProofImage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Captured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Capture a photo of the payment receipt or transaction screenshot',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (paymentProofImage == null)
            // Capture button
            GestureDetector(
              onTap: isCapturingImage ? null : _capturePaymentProof,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                  color: Colors.blue[700]!,
                  borderRadius: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCapturingImage)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      isCapturingImage
                          ? 'Opening Camera...'
                          : 'CAPTURE PAYMENT PROOF',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Preview with actions
            Column(
              children: [
                GestureDetector(
                  onTap: _viewPaymentProof,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(paymentProofImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _viewPaymentProof,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: NeumorphicStyle.neumorphicDecoration(
                            borderRadius: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _capturePaymentProof,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: NeumorphicStyle.neumorphicDecoration(
                            borderRadius: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _removePaymentProof,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: NeumorphicStyle.neumorphicDecoration(
                            borderRadius: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    if (isLoadingQrCode) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading QR Code...'),
            ],
          ),
        ),
      );
    }

    if (!qrCodeAvailable) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: Column(
          children: [
            Icon(Icons.qr_code_2, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'QR Code Not Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact admin to upload QR code for this branch',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Calculate amount to show
    final amountToShow =
        paidAmountController.text.isEmpty ? '0' : paidAmountController.text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          // Header with icon and title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              Text(
                'Scan QR to Pay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step 1: Amount to pay
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Amount to Pay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹$amountToShow',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 2: Scan QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Scan this QR Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // QR Code Image
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: qrCodeImageUrl != null
                      ? Image.network(
                          qrCodeImageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('QR Image load error: $error');
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Failed to load QR code',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : const Icon(Icons.qr_code_2, size: 200),
                ),
                const SizedBox(height: 12),

                // Payment details
                if (qrCodePaymentName != null && qrCodePaymentName!.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 16, color: Colors.green[900]),
                        const SizedBox(width: 8),
                        Text(
                          qrCodePaymentName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (qrCodeUpiId != null && qrCodeUpiId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'UPI ID: $qrCodeUpiId',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 3: Upload proof
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'After Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload screenshot below',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_downward, color: Colors.orange[700], size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    // Enable button if there's text in the input field (allow 0 or greater)
    final hasAmount = paidAmountController.text.isNotEmpty &&
        (double.tryParse(paidAmountController.text) ?? -1) >= 0;
    final isFullyPaid = paymentStatus == 'paid' && pendingAmount == 0;
    final isRecurring = widget.jobData?.isRecurringSeries ?? false;
    final showPaymentCollection = widget.jobData?.showPaymentCollection ?? true;

    // For recurring jobs that are already paid, show different button
    if (isRecurring && !showPaymentCollection && isFullyPaid) {
      return Container(
        decoration: NeumorphicStyle.coloredNeumorphicDecoration(
          color: Colors.green[700]!,
          borderRadius: 12,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSaving ? null : _completeJobWithoutPayment,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isSaving
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'COMPLETE JOB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
      );
    }

    return Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color:
            hasAmount && !isFullyPaid ? Colors.green[700]! : Colors.grey[400]!,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isSaving || !hasAmount || isFullyPaid) ? null : _savePayment,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isSaving
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
                      const Icon(Icons.save, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isFullyPaid
                            ? 'FULLY PAID'
                            : hasAmount
                                ? 'COMPLETE'
                                : 'ENTER AMOUNT',
                        textAlign: TextAlign.center,
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
    );
  }

  Future<void> _completeJobWithoutPayment() async {
    setState(() {
      isSaving = true;
    });

    try {
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (jobId == 0) {
        throw Exception('Invalid job ID');
      }

      // Complete the job without payment update (already paid)
      final completeResult = await ApiService.updateJobStatus(
        jobId,
        'completed',
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      if (completeResult['success'] == true) {
        // Job completed successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Job completed successfully! (Payment already received)',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Show receipt options dialog
        _showReceiptOptionsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to complete job: ${completeResult['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReceiptOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Job Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payment received successfully. Would you like to send a receipt to the customer?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildReceiptOption(
              icon: Icons.picture_as_pdf,
              label: 'Download PDF',
              color: Colors.red[700]!,
              onTap: () {
                Navigator.pop(context);
                _downloadPDFReceipt();
              },
            ),
            const SizedBox(height: 12),
            _buildReceiptOption(
              icon: Icons.chat,
              label: 'Share on WhatsApp',
              color: Colors.green[700]!,
              onTap: () {
                Navigator.pop(context);
                _shareOnWhatsApp();
              },
            ),
            const SizedBox(height: 12),
            _buildReceiptOption(
              icon: Icons.close,
              label: 'Skip',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                _redirectToHome();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPDFReceipt() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF receipt...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Create PDF document
      final pdf = pw.Document();

      // Get current date
      final now = DateTime.now();
      final dateStr =
          '${DateFormatter.formatDate(now)}, ${DateFormat('hh:mm a').format(now)}';

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'PAYMENT RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Pest Control Services',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          dateStr,
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 40),

                  // Divider
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 20),

                  // Customer Details
                  pw.Text(
                    'CUSTOMER DETAILS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildPdfRow('Name:', widget.job.name),
                  _buildPdfRow('Service:', widget.job.service),
                  _buildPdfRow('Address:', widget.job.address),
                  _buildPdfRow('Date:', widget.job.date),
                  pw.SizedBox(height: 30),

                  // Payment Details
                  pw.Text(
                    'PAYMENT DETAILS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Show base amount if there are addon services
                  if (widget.jobData?.addonServices != null &&
                      widget.jobData!.addonServices!.isNotEmpty) ...[
                    _buildPdfRow(
                      'Base Amount:',
                      'Rs ${(widget.jobData?.amount ?? widget.job.amount).toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Add-On Services:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    ...widget.jobData!.addonServices!.map((service) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
                        child: _buildPdfRow(
                          '+ ${service['service_name']}',
                          'Rs ${double.parse(service['amount'].toString()).toStringAsFixed(2)}',
                          valueColor: PdfColors.orange700,
                        ),
                      );
                    }),
                    pw.SizedBox(height: 5),
                    pw.Divider(),
                    pw.SizedBox(height: 5),
                  ],

                  _buildPdfRow(
                    'Total Amount:',
                    'Rs ${totalAmount.toStringAsFixed(2)}',
                  ),
                  _buildPdfRow(
                    'Paid Amount:',
                    'Rs ${paidAmount.toStringAsFixed(2)}',
                    valueColor: PdfColors.green700,
                  ),
                  _buildPdfRow(
                    'Pending Amount:',
                    'Rs ${pendingAmount.toStringAsFixed(2)}',
                    valueColor: pendingAmount > 0
                        ? PdfColors.orange700
                        : PdfColors.green700,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  _buildPdfRow(
                    'Payment Mode:',
                    _getPaymentModeText(selectedPaymentType),
                  ),
                  _buildPdfRow(
                    'Payment Status:',
                    _getPdfStatusText(),
                    valueColor: paymentStatus == 'paid'
                        ? PdfColors.green700
                        : PdfColors.orange700,
                  ),
                  pw.SizedBox(height: 40),

                  // Footer
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for your business!',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'For any queries, please contact us',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Save and share PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'receipt_${widget.job.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF receipt generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment then redirect
      await Future.delayed(const Duration(seconds: 1));
      _redirectToHome();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _redirectToHome();
    }
  }

  pw.Widget _buildPdfRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    try {
      // Get customer phone number
      final customerPhone = widget.jobData?.phone ?? widget.job.name;

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = customerPhone.replaceAll(RegExp(r'[^\d+]'), '');

      // Create receipt message
      final receiptMessage = '''
🧾 *Payment Receipt*

Customer: ${widget.job.name}
Service: ${widget.job.service}
Date: ${widget.job.date}

💰 *Payment Details:*${widget.jobData?.addonServices != null && widget.jobData!.addonServices!.isNotEmpty ? '\nBase Amount: Rs ${(widget.jobData?.amount ?? widget.job.amount).toStringAsFixed(2)}' : ''}${widget.jobData?.addonServices != null && widget.jobData!.addonServices!.isNotEmpty ? '\n\nAdd-On Services:\n${widget.jobData!.addonServices!.map((s) => '+ ${s['service_name']}: Rs ${double.parse(s['amount'].toString()).toStringAsFixed(2)}').join('\n')}\n' : ''}
Total Amount: Rs ${totalAmount.toStringAsFixed(2)}
Paid Amount: Rs ${paidAmount.toStringAsFixed(2)}
Pending Amount: Rs ${pendingAmount.toStringAsFixed(2)}
Payment Mode: ${_getPaymentModeText(selectedPaymentType)}
Status: ${_getReceiptStatusText()}

Thank you for your business! 🙏
      ''';

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(receiptMessage);

      // Try WhatsApp app scheme first (works better on Android)
      final whatsappAppUrl =
          'whatsapp://send?phone=$cleanPhone&text=$encodedMessage';
      final appUri = Uri.parse(whatsappAppUrl);

      bool launched = false;

      // Try app scheme first
      try {
        if (await canLaunchUrl(appUri)) {
          launched = await launchUrl(
            appUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('WhatsApp app scheme failed: $e');
      }

      // If app scheme failed, try web URL
      if (!launched) {
        final whatsappWebUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';
        final webUri = Uri.parse(whatsappWebUrl);

        try {
          launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('WhatsApp web URL failed: $e');
        }
      }

      if (!mounted) return;

      if (launched) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Wait a moment then redirect
        await Future.delayed(const Duration(seconds: 1));
        _redirectToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open WhatsApp. Please make sure it is installed.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        _redirectToHome();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _redirectToHome();
    }
  }

  String _getPaymentModeText(String mode) {
    switch (mode) {
      case 'upi':
        return 'UPI';
      default:
        return 'Cash';
    }
  }

  String _getReceiptStatusText() {
    switch (paymentStatus) {
      case 'paid':
        return 'Fully Paid ✅';
      case 'partial':
        return 'Partially Paid ⚠️';
      default:
        return 'Pending ⏳';
    }
  }

  String _getPdfStatusText() {
    switch (paymentStatus) {
      case 'paid':
        return 'Fully Paid';
      case 'partial':
        return 'Partially Paid';
      default:
        return 'Pending';
    }
  }

  void _redirectToHome() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to home...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    // Pop payment screen with result true
    Navigator.of(context).pop(true);
    // Pop job detail screen with result true to trigger refresh
    Navigator.of(context).pop(true);
  }

  // Complete and Reschedule Button
  Widget _buildCompleteAndRescheduleButton() {
    return Container(
      decoration: NeumorphicStyle.neumorphicDecoration(
        color: Colors.purple[700]!,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSchedulingRevisit ? null : _showCompleteAndRescheduleDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isSchedulingRevisit
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'COMPLETE & RESCHEDULE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
    );
  }

  // Schedule Revisit Button
  Widget _buildScheduleRevisitButton() {
    return Container(
      decoration: NeumorphicStyle.neumorphicDecoration(
        color: Colors.orange[700]!,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSchedulingRevisit ? null : _showScheduleRevisitDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isSchedulingRevisit
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_repeat, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'SCHEDULE REVISIT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
    );
  }

  // Show Schedule Revisit Dialog
  Future<void> _showScheduleRevisitDialog() async {
    // Set default date to tomorrow
    selectedRevisitDate = DateTime.now().add(const Duration(days: 1));
    selectedRevisitTime = const TimeOfDay(hour: 10, minute: 0);
    revisitReasonController.clear();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.event_repeat, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text('Schedule Revisit'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule a follow-up visit for incomplete work',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Date Picker
                ListTile(
                  tileColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: Colors.blue[700]),
                  title: const Text('Revisit Date'),
                  subtitle: Text(
                    selectedRevisitDate != null
                        ? DateFormatter.formatDate(selectedRevisitDate!)
                        : 'Select date',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedRevisitDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedRevisitDate = date;
                      });
                    }
                  },
                ),
                const Divider(),

                // Time Picker
                ListTile(
                  tileColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.access_time, color: Colors.green[700]),
                  title: const Text('Revisit Time'),
                  subtitle: Text(
                    selectedRevisitTime != null
                        ? selectedRevisitTime!.format(context)
                        : 'Select time',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedRevisitTime ??
                          const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        selectedRevisitTime = time;
                      });
                    }
                  },
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Reason TextField
                TextField(
                  controller: revisitReasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason (Optional)',
                    hintText: 'e.g., Customer requested additional treatment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _scheduleRevisit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  // Schedule Revisit API Call
  Future<void> _scheduleRevisit() async {
    if (selectedRevisitDate == null || selectedRevisitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSchedulingRevisit = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      // Format date and time
      final revisitDate = DateFormat('yyyy-MM-dd').format(selectedRevisitDate!);
      final revisitTime =
          '${selectedRevisitTime!.hour.toString().padLeft(2, '0')}:${selectedRevisitTime!.minute.toString().padLeft(2, '0')}';

      final result = await ApiService.scheduleRevisit(
        jobId: int.parse(widget.job.id),
        technicianId: technicianId,
        revisitDate: revisitDate,
        revisitTime: revisitTime,
        reason: revisitReasonController.text.trim().isEmpty
            ? null
            : revisitReasonController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSchedulingRevisit = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Revisit scheduled successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text('Revisit Scheduled!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('The revisit has been scheduled successfully.'),
                const SizedBox(height: 16),
                Text(
                  'Date: ${DateFormatter.formatDate(selectedRevisitDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Time: ${selectedRevisitTime!.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This visit will appear in the Marketing App\'s Visit tab.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _redirectToHome();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to schedule revisit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSchedulingRevisit = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Show Complete and Reschedule Dialog
  Future<void> _showCompleteAndRescheduleDialog() async {
    // Validate payment fields first
    if (selectedPaymentType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select payment mode first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (paidAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter paid amount first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Set default date to tomorrow
    selectedRevisitDate = DateTime.now().add(const Duration(days: 1));
    selectedRevisitTime = const TimeOfDay(hour: 10, minute: 0);
    revisitReasonController.clear();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.purple[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complete & Reschedule',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'This will:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Complete current job with payment\n2. Create new rescheduled job\n3. Both jobs will appear in system',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reschedule Date & Time',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                // Date Picker
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedRevisitDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedRevisitDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedRevisitDate != null
                              ? DateFormatter.formatDate(selectedRevisitDate!)
                              : 'Select Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedRevisitDate != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Time Picker
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedRevisitTime ??
                          const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedRevisitTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.purple[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedRevisitTime != null
                              ? selectedRevisitTime!.format(context)
                              : 'Select Time',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedRevisitTime != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Reason TextField
                TextField(
                  controller: revisitReasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason for Reschedule (Optional)',
                    hintText: 'e.g., Customer requested different date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeAndReschedule();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
              ),
              child: const Text('Complete & Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  // Complete and Reschedule API Call
  Future<void> _completeAndReschedule() async {
    if (selectedRevisitDate == null || selectedRevisitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSchedulingRevisit = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('Technician ID not found');
      }

      // Format date and time
      final rescheduleDate = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedRevisitDate!);
      final rescheduleTime =
          '${selectedRevisitTime!.hour.toString().padLeft(2, '0')}:${selectedRevisitTime!.minute.toString().padLeft(2, '0')}';

      // Get paid amount
      final paidAmount = double.tryParse(paidAmountController.text.trim()) ?? 0;

      // Convert payment proof image to base64 if exists
      String? paymentProofBase64;
      if (paymentProofImage != null) {
        final bytes = await paymentProofImage!.readAsBytes();
        paymentProofBase64 = base64Encode(bytes);
      }

      final result = await ApiService.completeAndReschedule(
        jobId: int.parse(widget.job.id),
        technicianId: technicianId,
        rescheduleDate: rescheduleDate,
        rescheduleTime: rescheduleTime,
        rescheduleReason: revisitReasonController.text.trim().isEmpty
            ? null
            : revisitReasonController.text.trim(),
        paymentMode: selectedPaymentType,
        paymentAccount: paymentAccountController.text.trim().isEmpty &&
                selectedPaymentType == 'upi' &&
                qrCodeUpiId != null
            ? qrCodeUpiId
            : paymentAccountController.text.trim(),
        paidAmount: paidAmount,
        paymentProof: paymentProofBase64,
      );

      if (!mounted) return;

      setState(() {
        isSchedulingRevisit = false;
      });

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Job completed and rescheduled successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show receipt options dialog (same as Complete button)
        _showReceiptOptionsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to complete and reschedule job',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSchedulingRevisit = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
