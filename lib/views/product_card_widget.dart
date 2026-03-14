import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/product.dart';
import '../viewmodels/feed_viewmodel.dart';
import 'product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FeedViewModel>();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: vm,
              child: ProductDetailView(product: product),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(product.imageUrl),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavoriteButton(
                        isFavorite: product.isFavorite,
                        onTap: () => vm.toggleFavorite(product.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Details ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location + time
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.45)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${product.location}  ·  ${timeago.format(product.createdAt, locale: 'ru')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
          .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF2A2A3C),
        child: const Icon(Icons.image, color: Colors.white24, size: 32),
      );
    }
    // Web support for blob URLs
    if (kIsWeb && (imageUrl.startsWith('blob:') || imageUrl.startsWith('http') || imageUrl.startsWith('/'))) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    // Support local file paths
    if (!kIsWeb && (imageUrl.startsWith('/') || imageUrl.startsWith('C:') || imageUrl.startsWith('D:'))) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: const Color(0xFF2A2A3C),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00AAFF),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF2A2A3C),
        child: const Icon(Icons.image_not_supported,
            color: Colors.white38, size: 32),
      ),
    );
  }
}

// ── Animated Favorite Button ─────────────────────────────────────────────────
class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _scale,
              builder: (_, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color:
                    widget.isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
