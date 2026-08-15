import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/neumorphic_style.dart';

class BagScreen extends StatefulWidget {
  final bool isIn;
  const BagScreen({super.key, required this.isIn});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final List<Map<String, dynamic>> bagItems = [
    {'name': 'Sprayer', 'quantity': 2, 'checked': false},
    {'name': 'Safety Mask', 'quantity': 5, 'checked': false},
    {'name': 'Gloves', 'quantity': 10, 'checked': false},
    {'name': 'Torch', 'quantity': 1, 'checked': false},
    {'name': 'Tools Kit', 'quantity': 1, 'checked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isIn ? 'Bag In' : 'Bag Out'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildChecklist(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
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
            widget.isIn ? Icons.work : Icons.work_off,
            size: 64,
            color: widget.isIn ? Colors.green[600] : Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isIn ? 'Check In Equipment' : 'Check Out Equipment',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equipment Checklist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...bagItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildChecklistItem(item, index);
          }),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                bagItems[index]['checked'] = !bagItems[index]['checked'];
              });
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: NeumorphicStyle.coloredNeumorphicDecoration(
                color: item['checked'] ? Colors.green[600]! : Colors.grey[400]!,
                borderRadius: 6,
              ),
              child: item['checked']
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item['name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 8),
            child: Text(
              'Qty: ${item['quantity']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allChecked = bagItems.every((item) => item['checked']);
    return Container(
      width: double.infinity,
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: allChecked
            ? (widget.isIn ? Colors.green[700]! : Colors.orange[700]!)
            : Colors.grey[400]!,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: allChecked ? _submitBag : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              widget.isIn ? 'CONFIRM BAG IN' : 'CONFIRM BAG OUT',
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
    );
  }

  void _submitBag() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Bag ${widget.isIn ? "in" : "out"} completed successfully!'),
      ),
    );
    Navigator.pop(context);
  }
}
