import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../viewmodels/feed_viewmodel.dart';
import 'product_card_widget.dart';
import 'category_bar_widget.dart';
import 'search_view.dart';
import 'notifications_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    final products = vm.products;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => vm.loadProducts(),
        color: const Color(0xFF00AAFF),
        backgroundColor: const Color(0xFF1E1E2C),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lalafo',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.06, end: 0, duration: 400.ms),
                          const SizedBox(height: 2),
                          Text(
                            'Объявления в Бишкеке',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search icon
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchView()),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: Colors.white70, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Notifications
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsView()),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white70, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category bar ────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 12),
                child: CategoryBar(),
              ),
            ),

            // ── Loading state ───────────────────────────────────────
            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00AAFF),
                    strokeWidth: 2,
                  ),
                ),
              )
            // ── Error state ─────────────────────────────────────────
            else if (vm.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 14),
                      Text(
                        vm.error!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => vm.loadProducts(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Повторить'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00AAFF),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // ── Empty state ─────────────────────────────────────────
            else if (products.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.12)),
                      const SizedBox(height: 14),
                      Text(
                        'Объявлений пока нет',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Станьте первым — подайте объявление!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // ── Masonry grid ────────────────────────────────────────
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      key: ValueKey(products[index].id),
                      product: products[index],
                    );
                  },
                ),
              ),

              // bottom spacing for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}
