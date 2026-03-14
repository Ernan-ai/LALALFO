import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../viewmodels/feed_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'product_detail_view.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedViewModel>();
    final auth = context.watch<AuthViewModel>();
    final products = feed.products;


    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Уведомления',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  Text('Нет уведомлений',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.25))),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                final isOwn =
                    auth.isLoggedIn && p.userId == auth.currentUser?.uid;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: feed,
                        child: ProductDetailView(product: p),
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isOwn
                                ? const Color(0xFF00AAFF)
                                    .withValues(alpha: 0.15)
                                : const Color(0xFF2A2A3C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isOwn
                                ? Icons.check_circle_outline_rounded
                                : Icons.new_releases_outlined,
                            color: isOwn
                                ? const Color(0xFF00AAFF)
                                : Colors.orangeAccent.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOwn
                                    ? 'Ваше объявление опубликовано'
                                    : 'Новое объявление',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.title} — ${p.formattedPrice}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.45)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeago.format(p.createdAt, locale: 'ru'),
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.white.withValues(alpha: 0.3)),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: Duration(milliseconds: i * 30));
              },
            ),
    );
  }
}
