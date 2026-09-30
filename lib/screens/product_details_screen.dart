import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isAddingToCart = false;

  // Add the selected product to the signed-in user's persistent local cart.
  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      final user = await UserService().getUser();
      if (user.id <= 0) {
        throw StateError('Please sign in before adding products to your cart.');
      }
      await CartService().addProduct(userId: user.id, product: widget.product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to your cart.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add the product right now.')),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, size: 24.sp),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENHANCEMENT 2: hero image of the selected product.
              Container(
                width: double.infinity,
                height: 260.h,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(Icons.image, size: 40.sp),
                ),
              ),
              SizedBox(height: 16.h),

              // ENHANCEMENT 2: category pill.
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: CustomText(
                    text: product.category.toUpperCase(),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // ENHANCEMENT 2: title, price and rating.
              CustomText(
                text: product.title,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(width: 12.w),
                  Icon(Icons.star, size: 16.sp, color: Colors.amber),
                  SizedBox(width: 4.w),
                  CustomText(
                    text: '${product.rating} (${product.reviews.length})',
                    fontSize: 13.sp,
                  ),
                  const Spacer(),
                  CustomText(
                    text: product.availabilityStatus,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // ENHANCEMENT 2: full description.
              CustomText(
                text: product.description,
                fontSize: 13.sp,
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 24.h),

              // ENHANCEMENT 3: uses the API's add-cart endpoint with this product.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  icon: _isAddingToCart
                      ? SizedBox(
                          height: 18.sp,
                          width: 18.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(_isAddingToCart ? 'Adding...' : 'Add to cart'),
                ),
              ),
              SizedBox(height: 24.h),

              // ENHANCEMENT 2: remaining fields returned by the API.
              CustomText(
                text: 'PRODUCT INFO',
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
              SizedBox(height: 8.h),
              _infoRow('Brand', product.brand),
              _infoRow('SKU', product.sku),
              _infoRow('Stock', '${product.stock}'),
              _infoRow('Discount', '${product.discountPercentage}%'),
              _infoRow('Weight', '${product.weight}'),
              _infoRow(
                'Dimensions',
                '${product.dimensions.width} x '
                    '${product.dimensions.height} x '
                    '${product.dimensions.depth}',
              ),
              _infoRow('Warranty', product.warrantyInformation),
              _infoRow('Shipping', product.shippingInformation),
              _infoRow('Return policy', product.returnPolicy),
              _infoRow('Min. order', '${product.minimumOrderQuantity}'),
              _infoRow('Tags', product.tags.join(', ')),

              // ENHANCEMENT 2: reviews section.
              if (product.reviews.isNotEmpty) ...[
                SizedBox(height: 24.h),
                CustomText(
                  text: 'REVIEWS',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
                SizedBox(height: 8.h),
                ...product.reviews.map(
                  (review) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomText(
                              text: review.reviewerName,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.star, size: 13.sp, color: Colors.amber),
                            SizedBox(width: 2.w),
                            CustomText(
                              text: '${review.rating}',
                              fontSize: 12.sp,
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        CustomText(text: review.comment, fontSize: 12.sp),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ENHANCEMENT 2: single label/value line used by the info section.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
