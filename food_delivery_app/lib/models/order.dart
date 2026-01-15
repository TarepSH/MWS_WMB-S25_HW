import 'menu_item.dart';

class OrderItemLine {
  final int menuId;
  final int quantity;
  final double price;
  final MenuItem? menu;

  OrderItemLine({
    required this.menuId,
    required this.quantity,
    required this.price,
    required this.menu,
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      menuId: (json['menuId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      price: double.tryParse('${json['price']}') ?? 0,
      menu: json['menu'] == null ? null : MenuItem.fromJson(json['menu'] as Map<String, dynamic>),
    );
  }
}

class Order {
  final int orderId;
  final int userId;
  final int restaurantId;
  final String orderStatus;
  final double totalAmount;
  final List<OrderItemLine> items;

  Order({
    required this.orderId,
    required this.userId,
    required this.restaurantId,
    required this.orderStatus,
    required this.totalAmount,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final linesRaw = (json['orderItems'] as List<dynamic>? ?? const []);
    return Order(
      orderId: (json['orderId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      restaurantId: (json['restaurantId'] as num).toInt(),
      orderStatus: '${json['orderStatus']}',
      totalAmount: double.tryParse('${json['totalAmount']}') ?? 0,
      items: linesRaw.map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
