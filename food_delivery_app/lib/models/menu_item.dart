class MenuItem {
  final int menuId;
  final int restaurantId;
  final String itemName;
  final String description;
  final double price;
  final String imageUrl;
  final String availabilityStatus;

  MenuItem({
    required this.menuId,
    required this.restaurantId,
    required this.itemName,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.availabilityStatus,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      menuId: (json['menuId'] as num).toInt(),
      restaurantId: (json['restaurantId'] as num).toInt(),
      itemName: json['itemName'] as String,
      description: json['description'] as String,
      price: double.tryParse('${json['price']}') ?? 0,
      imageUrl: json['imageUrl'] as String,
      availabilityStatus: '${json['availabilityStatus']}',
    );
  }
}
