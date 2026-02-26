/// product_card.dart
///
/// Presentational widget for a single product in the listing.
/// Contains NO business logic — it displays whatever [Product] is passed in.
///
/// Layout:
///   ┌────────────────────┐
///   │  [CachedImage]     │  ← square product photo
///   │  Title (2 lines)   │
///   │  ★★★★☆  (3.9/5)   │  ← star row + count
///   │  $109.95           │  ← price
///   │  [Add to Cart]     │  ← placeholder button
///   └────────────────────┘
///
/// Used inside a SliverGrid (2-column) on the product listing screen.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  // Callback fired when "Add to Cart" is tapped.
  // Optional so the widget can be used read-only in previews.
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias, // image corners respect the Card's radius
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product image ─────────────────────────────────────────────────
          _buildImage(),

          // ── Text details ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 4),
                _buildRatingRow(),
                const SizedBox(height: 4),
                _buildPrice(),
              ],
            ),
          ),

          // ── Add to Cart button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: _buildAddToCartButton(context),
          ),
        ],
      ),
    );
  }

  // ── Private builders ──────────────────────────────────────────────────────

  Widget _buildImage() {
    return AspectRatio(
      // Square image region — works in both grid and list layouts.
      aspectRatio: 1,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: CachedNetworkImage(
          imageUrl: product.image,

          // Placeholder shown while the image loads — keeps layout stable.
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          // Fallback shown if the URL is broken or there's no internet.
          errorWidget: (_, __, ___) => const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 40,
          ),

          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      product.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }

  Widget _buildRatingRow() {
    // Build a row of 5 star icons coloured based on the rating value.
    // E.g. rating.rate = 3.9 → 3 full stars + 1 half star + 1 empty star.
    final rate = product.rating.rate;
    final count = product.rating.count;

    return Row(
      children: [
        // ── Star icons ─────────────────────────────────────────────────────
        ...List.generate(5, (i) {
          final starValue = i + 1; // 1-based position
          IconData icon;

          if (rate >= starValue) {
            icon = Icons.star; // full star
          } else if (rate >= starValue - 0.5) {
            icon = Icons.star_half; // half star
          } else {
            icon = Icons.star_border; // empty star
          }

          return Icon(icon, size: 12, color: const Color(0xFFFFB400));
        }),
        const SizedBox(width: 4),

        // ── Review count ───────────────────────────────────────────────────
        Text(
          '($count)',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Text(
      '\$${product.price.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF6000), // Daraz orange
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: OutlinedButton(
        onPressed: onAddToCart,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF6000)),
          foregroundColor: const Color(0xFFFF6000),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: const Text(
          'Add to Cart',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
