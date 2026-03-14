import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../viewmodels/feed_viewmodel.dart';
import 'product_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> all) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return all.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    final allProducts = vm.products;
    final results = _filter(allProducts);

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
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Поиск объявлений...',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildHints()
          : results.isEmpty
              ? _buildEmpty()
              : _buildResults(results, vm),
    );
  }

  Widget _buildHints() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 56, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            'Введите название, категорию или город',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Text(
            'Ничего не найдено по «$_query»',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Product> results, FeedViewModel vm) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: ProductDetailView(product: p),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _buildThumb(p.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(p.formattedPrice,
                          style: const TextStyle(
                              color: Color(0xFF00AAFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${p.location}  ·  ${p.category}',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms, delay: Duration(milliseconds: i * 40));
      },
    );
  }

  Widget _buildThumb(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFF2A2A3C),
        child: const Icon(Icons.image, color: Colors.white24, size: 24),
      );
    }
    if (url.startsWith('/') || url.startsWith('C:') || url.startsWith('D:')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Image.network(url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF2A2A3C),
            child: const Icon(Icons.image, color: Colors.white24, size: 24)));
  }
}
