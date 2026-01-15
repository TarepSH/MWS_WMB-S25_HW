import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import '../models/tracking.dart';
import '../models/user.dart';
import '../state/cart_state.dart';

class ApiService {
  final Dio _dio;

  ApiService({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  static String defaultBaseUrl() {
    // Android Emulator: host machine is 10.0.2.2
    if (kIsWeb) return 'http://localhost:3001';
    return 'http://10.0.2.2:3001';
  }

  Future<({String token, User user})> login({required String username, required String password}) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = res.data as Map<String, dynamic>;
    return (token: data['token'] as String, user: User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<List<Restaurant>> getRestaurants() async {
    final res = await _dio.get('/restaurants');
    final list = (res.data as List<dynamic>);
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MenuItem>> getMenus(int restaurantId) async {
    final res = await _dio.get('/restaurants/$restaurantId/menus');
    final list = (res.data as List<dynamic>);
    return list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> createOrder({
    required String token,
    required int restaurantId,
    required List<CartLine> cartLines,
    required String paymentMethod,
    required String address,
  }) async {
    final items = cartLines
        .map((l) => {
              'menuId': l.item.menuId,
              'quantity': l.quantity,
            })
        .toList();

    final res = await _dio.post(
      '/orders',
      data: {
        'restaurantId': restaurantId,
        'items': items,
        'paymentMethod': paymentMethod,
        'address': address,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> payOrder({required String token, required int orderId}) async {
    await _dio.post(
      '/orders/$orderId/pay',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Tracking> getTracking({required String token, required int orderId}) async {
    final res = await _dio.get(
      '/orders/$orderId/tracking',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Tracking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markDelivered({required String token, required int orderId}) async {
    await _dio.post(
      '/orders/$orderId/mark-delivered',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> submitReview({
    required String token,
    required int orderId,
    required int rating,
    required String? comment,
  }) async {
    await _dio.post(
      '/reviews',
      data: {
        'orderId': orderId,
        'rating': rating,
        'comment': (comment == null || comment.trim().isEmpty) ? null : comment.trim(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
