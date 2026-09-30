class Cart {
  const Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int? ?? 0,
      products: (json['products'] as List? ?? [])
          .map(
            (product) => CartProduct.fromJson(product as Map<String, dynamic>),
          )
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0,
      userId: json['userId'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalQuantity: json['totalQuantity'] as int? ?? 0,
    );
  }

  Cart copyWith({
    List<CartProduct>? products,
    double? total,
    double? discountedTotal,
    int? totalProducts,
    int? totalQuantity,
  }) {
    return Cart(
      id: id,
      products: products ?? this.products,
      total: total ?? this.total,
      discountedTotal: discountedTotal ?? this.discountedTotal,
      userId: userId,
      totalProducts: totalProducts ?? this.totalProducts,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }
}

class CartProduct {
  const CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final discountPercentage =
        (json['discountPercentage'] as num?)?.toDouble() ?? 0;
    final discountedPrice =
        (json['discountedPrice'] as num?)?.toDouble() ??
        price * (1 - discountPercentage / 100);
    final total = (json['total'] as num?)?.toDouble() ?? price * quantity;

    return CartProduct(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      price: price,
      quantity: quantity,
      total: total,
      discountPercentage: discountPercentage,
      // DummyJSON's cart payload may give the per-item discounted price when
      // discountedTotal is not present. Scale it to the full item total.
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ??
          discountedPrice * quantity,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  CartProduct copyWith({int? quantity}) {
    final nextQuantity = quantity ?? this.quantity;
    return CartProduct(
      id: id,
      title: title,
      price: price,
      quantity: nextQuantity,
      total: price * nextQuantity,
      discountPercentage: discountPercentage,
      discountedTotal: price * nextQuantity * (1 - discountPercentage / 100),
      thumbnail: thumbnail,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'quantity': quantity,
    'total': total,
    'discountPercentage': discountPercentage,
    'discountedPrice': price * (1 - discountPercentage / 100),
    'discountedTotal': discountedTotal,
    'thumbnail': thumbnail,
  };
}
