import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products?limit=0'),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load products.');
    }

    final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
    final productsJson = decodedJson['products'] as List? ?? [];
    return productsJson.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await http.get(
      Uri.parse(
        'https://dummyjson.com/products/search?q=${Uri.encodeQueryComponent(query)}',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to search products.');
    }

    final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
    final productsJson = decodedJson['products'] as List? ?? [];
    return productsJson.map((json) => Product.fromJson(json)).toList();
  }

  // ENHANCEMENT 1: cart items only contain summary data, so load the full
  // product before reusing ProductDetailsScreen.
  Future<Product> getProductById(int productId) async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products/$productId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load product $productId.');
    }
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
