class JobModel {
  final String id;
  final String name;
  final String address;
  final String service;
  final String treatment;
  final String? flatSize; // Add flat size field
  final String area;
  final String time;
  final String date;
  final String paidType;
  final double amount;
  final String? note;

  JobModel({
    required this.id,
    required this.name,
    required this.address,
    required this.service,
    required this.treatment,
    this.flatSize, // Add to constructor
    required this.area,
    required this.time,
    required this.date,
    required this.paidType,
    required this.amount,
    this.note,
  });
}

class JobStats {
  final int pending;
  final int completed;
  final double online;
  final double cash;
  final double cashPending;

  JobStats({
    required this.pending,
    required this.completed,
    required this.online,
    required this.cash,
    required this.cashPending,
  });
}
