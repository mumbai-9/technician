class Technician {
  final int id;
  final String name;
  final String code;
  final String userId;
  final String? email;
  final String? phone;
  final String? myReference;
  final String? city;
  final String? state;
  final String? address;
  final bool isActive;

  Technician({
    required this.id,
    required this.name,
    required this.code,
    required this.userId,
    this.email,
    this.phone,
    this.myReference,
    this.city,
    this.state,
    this.address,
    required this.isActive,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      userId: json['user_id'],
      email: json['email'],
      phone: json['phone'],
      myReference: json['my_reference'],
      city: json['city'],
      state: json['state'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'user_id': userId,
      'email': email,
      'phone': phone,
      'my_reference': myReference,
      'city': city,
      'state': state,
      'address': address,
      'is_active': isActive,
    };
  }
}
