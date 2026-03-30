import 'package:flutter/material.dart';
import 'product.dart';

class Favorites extends ChangeNotifier {
  final Map<String, Product> _items = {};

  Map<String, Product> get items => {..._items};

  bool isFavorite(String productId) {
    return _items.containsKey(productId);
  }

  void toggleFavorite(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items.putIfAbsent(product.id, () => product);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
