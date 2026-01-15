class Tracking {
  final int orderId;
  final String orderStatus;
  final String deliveryStatus;
  final String driverName;
  final String driverPhone;
  final String vehicleType;
  final double lat;
  final double lng;
  final int etaMinutes;

  Tracking({
    required this.orderId,
    required this.orderStatus,
    required this.deliveryStatus,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleType,
    required this.lat,
    required this.lng,
    required this.etaMinutes,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>;
    final loc = json['driverLocation'] as Map<String, dynamic>;
    return Tracking(
      orderId: (json['orderId'] as num).toInt(),
      orderStatus: '${json['orderStatus']}',
      deliveryStatus: '${json['deliveryStatus']}',
      driverName: driver['name'] as String,
      driverPhone: driver['phone'] as String,
      vehicleType: driver['vehicleType'] as String,
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      etaMinutes: (json['etaMinutes'] as num).toInt(),
    );
  }
}
