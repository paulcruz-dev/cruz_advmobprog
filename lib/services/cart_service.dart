import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import '../models/product_model.dart';

class CartService {
  static const _storagePrefix = 'cart_';

  // Every cart screen observes this so an item added on the product page is
  // immediately visible after returning to the cart tab.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  // The DummyJSON cart API simulates POST requests; it never persists them.
  // Store each signed-in user's cart locally so Add to cart really updates it.
  Future<Cart> getCartByUserId(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final rawCart = preferences.getString('$_storagePrefix$userId');
    if (rawCart == null) {
      return _buildCart(userId, const []);
    }
    final data = jsonDecode(rawCart) as List<dynamic>;
    final products = data
        .map((item) => CartProduct.fromJson(item as Map<String, dynamic>))
        .toList();
    return _buildCart(userId, products);
  }

  Future<Cart> addProduct({
    required int userId,
    required Product product,
    int quantity = 1,
  }) async {
    final cart = await getCartByUserId(userId);
    final existingIndex = cart.products.indexWhere(
      (item) => item.id == product.id,
    );
    final products = [...cart.products];
    if (existingIndex >= 0) {
      products[existingIndex] = products[existingIndex].copyWith(
        quantity: products[existingIndex].quantity + quantity,
      );
    } else {
      products.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: quantity,
          total: product.price * quantity,
          discountPercentage: product.discountPercentage,
          discountedTotal:
              product.price * quantity * (1 - product.discountPercentage / 100),
          thumbnail: product.thumbnail,
        ),
      );
    }
    return _saveCart(userId, products);
  }

  Future<Cart> updateProductQuantity({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final cart = await getCartByUserId(userId);
    final products = cart.products
        .where((item) => item.id != productId || quantity > 0)
        .map(
          (item) =>
              item.id == productId ? item.copyWith(quantity: quantity) : item,
        )
        .toList();
    return _saveCart(userId, products);
  }

  Future<Cart> _saveCart(int userId, List<CartProduct> products) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_storagePrefix$userId',
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
    changes.value++;
    return _buildCart(userId, products);
  }

  Cart _buildCart(int userId, List<CartProduct> products) {
    final total = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discountedTotal = products.fold<double>(
      0,
      (sum, product) =>
          sum +
          product.price *
              product.quantity *
              (1 - product.discountPercentage / 100),
    );
    return Cart(
      id: userId,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      userId: userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, product) => sum + product.quantity),
    );
  }
}
