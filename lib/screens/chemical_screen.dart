import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';

class ChemicalScreen extends StatefulWidget {
  final bool isIn;
  const ChemicalScreen({super.key, required this.isIn});

  @override
  State<ChemicalScreen> createState() => _ChemicalScreenState();
}

class _ChemicalScreenState extends State<ChemicalScreen> {
  final TextEditingController quantityController = TextEditingController();
  String? userId;
  int? selectedChemicalId;
  String selectedChemicalName = '';
  bool isLoading = false;
  List<dynamic> chemicals = [];
  List<dynamic> inventory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchChemicals();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    if (userId != null) {
      _fetchInventory();
    }
  }

  Future<void> _fetchChemicals() async {
    try {
      final response = await ApiService.getActiveChemicals();
      setState(() {
        chemicals = response;
        if (chemicals.isNotEmpty) {
          selectedChemicalId = chemicals[0]['id'];
          selectedChemicalName = chemicals[0]['name'];
        }
      });
    } catch (e) {
      print('Error fetching chemicals: $e');
    }
  }

  Future<void> _fetchInventory() async {
    if (userId == null) return;

    try {
      final response = await ApiService.getChemicalInventory(userId: userId!);
      if (response['success'] == true) {
        setState(() {
          inventory = response['inventory'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isIn ? 'Chemical In' : 'Chemical Out'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchChemicals();
              _fetchInventory();
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
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildForm(),
                      const SizedBox(height: 24),
                      _buildInventory(),
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
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Icon(
            widget.isIn ? Icons.arrow_downward : Icons.arrow_upward,
            size: 64,
            color: widget.isIn ? Colors.green[600] : Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isIn ? 'Receive Chemicals' : 'Issue Chemicals',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chemical Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (chemicals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No chemicals available. Please contact admin.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration:
                  NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
              child: DropdownButton<int>(
                value: selectedChemicalId,
                isExpanded: true,
                underline: const SizedBox(),
                items: chemicals.map<DropdownMenuItem<int>>((chem) {
                  return DropdownMenuItem<int>(
                    value: chem['id'],
                    child: Text('${chem['name']} (${chem['unit']})'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedChemicalId = newValue;
                    final selected =
                        chemicals.firstWhere((c) => c['id'] == newValue);
                    selectedChemicalName = selected['name'];
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration:
                  NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
              child: TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Quantity',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.science),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                color: widget.isIn ? Colors.green[700]! : Colors.orange[700]!,
                borderRadius: 12,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitChemical,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.isIn ? 'RECEIVE CHEMICAL' : 'ISSUE CHEMICAL',
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
        ],
      ),
    );
  }

  Widget _buildInventory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (inventory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No inventory available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...inventory.map((item) => _buildInventoryItem(item)),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Available Stock',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.blue[600]!,
              borderRadius: 10,
            ),
            child: Text(
              '${double.parse(item['current_stock'].toString()).toStringAsFixed(2)} ${item['unit']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitChemical() async {
    if (quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity')),
      );
      return;
    }

    if (selectedChemicalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chemical')),
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
      final response = await ApiService.recordChemicalTransaction(
        userId: userId!,
        chemicalId: selectedChemicalId!,
        type: widget.isIn ? 'in' : 'out',
        quantity: double.parse(quantityController.text),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        time: DateFormat('HH:mm:ss').format(DateTime.now()),
      );

      setState(() {
        isLoading = false;
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Chemical ${widget.isIn ? "received" : "issued"} successfully!'),
            ),
          );
        }

        // Refresh inventory
        _fetchInventory();

        // Clear form
        quantityController.clear();

        // Go back after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message'] ?? 'Failed to record transaction')),
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
    quantityController.dispose();
    super.dispose();
  }
}
