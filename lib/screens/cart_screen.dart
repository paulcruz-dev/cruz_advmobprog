import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart> _cartFuture;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
    CartService.changes.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.changes.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      _refreshCart();
    }
  }

  // Reload when a product is added or when the user pulls to refresh.
  Future<void> _refreshCart() async {
    setState(() {
      _cartFuture = _loadCart();
    });
    await _cartFuture;
  }

  Future<Cart> _loadCart() async {
    // Load only this signed-in user's persisted cart.
    final user = await UserService().getUser();
    if (user.id <= 0) {
      throw StateError('Sign in to view your cart.');
    }
    _currentUserId = user.id;
    return CartService().getCartByUserId(user.id);
  }

  Future<void> _changeQuantity(CartProduct product, int difference) async {
    final nextQuantity = product.quantity + difference;
    if (nextQuantity < 1) return;
    try {
      final cart = await CartService().updateProductQuantity(
        userId: _currentUserId,
        productId: product.id,
        quantity: nextQuantity,
      );
      if (!mounted) return;
      setState(() => _cartFuture = Future.value(cart));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update the cart right now.')),
      );
    }
  }

  // ENHANCEMENT 1: retrieve full product data before opening the shared detail screen.
  Future<void> _openProduct(CartProduct cartProduct) async {
    try {
      final Product product = await ProductService().getProductById(
        cartProduct.id,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load that product right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cart>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(text: 'Could not load the cart.', fontSize: 15.sp),
                  SizedBox(height: 12.h),
                  FilledButton.icon(
                    onPressed: _refreshCart,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final cart = snapshot.data!;
        final total = cart.discountedTotal;

        if (cart.products.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshCart,
            child: ListView(
              padding: EdgeInsets.all(24.r),
              children: [
                SizedBox(height: 130.h),
                Icon(Icons.shopping_cart_outlined, size: 54.sp),
                SizedBox(height: 14.h),
                CustomText(
                  text: 'Your cart is empty',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: 'Add a product from the shop to see it here.',
                  fontSize: 13.sp,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCart,
                child: ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    // ENHANCEMENT 1: summary for the single cart fetched by user id.
                    CustomText(
                      text: 'Your cart',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text:
                          '${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'} in your cart',
                      fontSize: 12.sp,
                    ),
                    SizedBox(height: 12.h),
                    ...cart.products.map((product) => _cartItem(product)),
                  ],
                ),
              ),
            ),
            // ENHANCEMENT 1: checkout summary updates with the on-screen quantity controls.
            _checkoutSummary(total),
          ],
        );
      },
    );
  }

  Widget _cartItem(CartProduct product) {
    final quantity = product.quantity;
    final itemTotal = product.price * quantity;
    final discountedTotal = itemTotal * (1 - product.discountPercentage / 100);
    const accentColor = Color(0xFFFFC107);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black12,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: InkWell(
          // ENHANCEMENT 1: cart items remain clickable and reuse detail_screen.
          onTap: () => _openProduct(product),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.network(
                    product.thumbnail,
                    height: 72.h,
                    width: 72.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(Icons.image, size: 28.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: product.title,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      CustomText(text: 'ID: ${product.id}', fontSize: 11.sp),
                      SizedBox(height: 5.h),
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text:
                            '${product.discountPercentage.toStringAsFixed(0)}% off - \$${discountedTotal.toStringAsFixed(2)} total',
                        fontSize: 10.sp,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton.filled(
                      onPressed: () => _changeQuantity(product, 1),
                      style: IconButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.add),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: CustomText(
                        text: '$quantity',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: quantity > 1
                          ? () => _changeQuantity(product, -1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutSummary(double total) {
    const accentColor = Color(0xFFFFC107);
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            _summaryRow('Subtotal', total),
            SizedBox(height: 4.h),
            _summaryRow('Delivery fee', 0),
            Divider(height: 20.h),
            _summaryRow('Total', total, isBold: true),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order confirmation is ready.'),
                    ),
                  );
                },
                child: const Text('Confirm Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: isBold ? 15.sp : 12.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        CustomText(
          text: '\$${amount.toStringAsFixed(2)}',
          fontSize: isBold ? 15.sp : 12.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ],
    );
  }
}
