class Branch {
  final int id;
  final String name;
  final String code;
  final String address;
  final String city;
  final String state;
  final String phone;
  final String email;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.city,
    required this.state,
    required this.phone,
    required this.email,
    required this.isActive,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'state': state,
      'phone': phone,
      'email': email,
      'is_active': isActive ? 1 : 0,
    };
  }
}
