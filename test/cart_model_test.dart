import 'package:cruz_advmobprog/models/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CartProduct.fromJson derives discounted total from discountedPrice and quantity',
    () {
      final product = CartProduct.fromJson({
        'id': 1,
        'title': 'Wireless Mouse',
        'price': 10,
        'quantity': 3,
        'total': 30,
        'discountPercentage': 20,
        'discountedPrice': 8,
        'thumbnail': 'https://example.com/mouse.png',
      });

      expect(product.price, 10);
      expect(product.quantity, 3);
      expect(product.total, 30);
      expect(product.discountedTotal, 24);
    },
  );
}
