class Restaurant {
  final int restaurantId;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final String cuisineType;

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.cuisineType,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      restaurantId: (json['restaurantId'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      cuisineType: json['cuisineType'] as String,
    );
  }
}
