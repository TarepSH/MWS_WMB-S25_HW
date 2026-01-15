import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';

class CartLine {
  final MenuItem item;
  int quantity;
  String note;

  CartLine({required this.item, required this.quantity, required this.note});
}

class CartState extends ChangeNotifier {
  final Map<int, CartLine> _lines = {};
  int? _restaurantId;

  List<CartLine> get lines => _lines.values.toList(growable: false);

  int? get restaurantId => _restaurantId;

  bool get isEmpty => _lines.isEmpty;

  double get total {
    double sum = 0;
    for (final line in _lines.values) {
      sum += line.item.price * line.quantity;
    }
    return sum;
  }

  void add(MenuItem item, {String note = ''}) {
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      _lines.clear();
    }
    _restaurantId = item.restaurantId;

    final existing = _lines[item.menuId];
    if (existing != null) {
      existing.quantity += 1;
      if (note.trim().isNotEmpty) {
        existing.note = note.trim();
      }
    } else {
      _lines[item.menuId] = CartLine(item: item, quantity: 1, note: note.trim());
    }
    notifyListeners();
  }

  void setQuantity(int menuId, int quantity) {
    final existing = _lines[menuId];
    if (existing == null) return;

    if (quantity <= 0) {
      _lines.remove(menuId);
    } else {
      existing.quantity = quantity;
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _restaurantId = null;
    notifyListeners();
  }
}
