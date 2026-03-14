import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/product.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'auth_view.dart';
import 'chat_room_view.dart';

class ProductDetailView extends StatelessWidget {
  final Product product;
  const ProductDetailView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    // Find the live product (in case favorite changed)
    final liveProducts = vm.products;
    final live = liveProducts.where((p) => p.id == product.id).firstOrNull;
    final p = live ?? product;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Image ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => vm.toggleFavorite(p.id),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    p.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: p.isFavorite
                        ? const Color(0xFFFF4D6D)
                        : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImage(p.imageUrl),
            ),
          ),

          // ── Details body ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF12121F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    p.formattedPrice,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    p.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location & time row
                  _infoRow(Icons.location_on_outlined, p.location),
                  const SizedBox(height: 8),
                  _infoRow(Icons.access_time_rounded,
                      timeago.format(p.createdAt, locale: 'ru')),
                  const SizedBox(height: 8),
                  _infoRow(Icons.category_outlined, p.category),

                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Описание',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.description.isNotEmpty
                        ? p.description
                        : 'Продавец не добавил описание.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final auth = context.read<AuthViewModel>();
                        if (!auth.isLoggedIn) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AuthView()));
                          return;
                        }
                        if (p.userId == auth.currentUser?.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Это ваше объявление'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        try {
                          final chatVm = context.read<ChatViewModel>();
                          final chatId = await chatVm.getOrCreateChat(
                            sellerId: p.userId,
                            sellerName: 'Продавец',
                            productId: p.id,
                            productTitle: p.title,
                          );
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomView(
                                  chatId: chatId,
                                  otherUserName: 'Продавец',
                                  productTitle: p.title,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 20),
                      label: const Text('Написать продавцу',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AAFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Phone button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: const Text('Позвонить',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00AAFF),
                        side: const BorderSide(
                            color: Color(0xFF00AAFF), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
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
              strokeWidth: 2, color: Color(0xFF00AAFF)),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF2A2A3C),
        child: const Icon(Icons.image_not_supported,
            color: Colors.white38, size: 48),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}
