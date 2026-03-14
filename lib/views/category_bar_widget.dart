import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../viewmodels/feed_viewmodel.dart';

class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FeedViewModel.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = FeedViewModel.categories[i];
          final selected = cat == vm.selectedCategory;
          return GestureDetector(
            onTap: () => vm.filterByCategory(cat),
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00AAFF)
                    : const Color(0xFF2A2A3C),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00AAFF)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
              .animate(target: selected ? 1 : 0)
              .scaleXY(begin: 1, end: 1.05, duration: 200.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}
