class User {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String? address;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['userId'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}
