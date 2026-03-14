import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/feed_viewmodel.dart';
import 'auth_view.dart';

class SellView extends StatefulWidget {
  const SellView({super.key});

  @override
  State<SellView> createState() => _SellViewState();
}

class _SellViewState extends State<SellView> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Бишкек');
  String _category = 'Транспорт';
  String? _imagePath;
  bool _submitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;

    String finalPath = picked.path;

    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      finalPath = savedFile.path;
    }
    
    setState(() => _imagePath = finalPath);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthViewModel>();
    if (!auth.isLoggedIn) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AuthView()));
      return;
    }

    if (_titleCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните название и цену'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final product = Product(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0,
      imageUrl: _imagePath ?? '',
      location: _locationCtrl.text.trim(),
      category: _category,
      createdAt: DateTime.now(),
      userId: auth.currentUser!.uid,
    );

    try {
      await context.read<FeedViewModel>().addProduct(product);
      if (mounted) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _priceCtrl.clear();
        _locationCtrl.text = 'Бишкек';
        setState(() {
          _imagePath = null;
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Объявление опубликовано! 🎉'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF00AAFF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подать объявление',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 300.ms),

            if (!auth.isLoggedIn) ...[
              const SizedBox(height: 24),
              _buildLoginPrompt(),
            ] else ...[
              const SizedBox(height: 24),

              // Image picker
              _buildImagePicker(),
              const SizedBox(height: 20),

              // Title
              _buildField(
                controller: _titleCtrl,
                hint: 'Название *',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 14),

              // Description
              _buildField(
                controller: _descCtrl,
                hint: 'Описание',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 14),

              // Price
              _buildField(
                controller: _priceCtrl,
                hint: 'Цена (KGS) *',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              // Category dropdown
              _buildCategoryPicker(),
              const SizedBox(height: 14),

              // Location
              _buildField(
                controller: _locationCtrl,
                hint: 'Город',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AAFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF00AAFF).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Опубликовать',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline,
              size: 48, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Войдите, чтобы подать объявление',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AuthView())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AAFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Войти',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00AAFF).withValues(alpha: 0.2),
            width: 1.5,
          ),
          image: _imagePath != null
              ? DecorationImage(
                  image: kIsWeb || _imagePath!.startsWith('http') || _imagePath!.startsWith('blob:')
                      ? NetworkImage(_imagePath!) as ImageProvider
                      : FileImage(File(_imagePath!)),
                  fit: BoxFit.cover)
              : null,
        ),
        child: _imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(height: 10),
                  Text(
                    'Добавить фото',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF00AAFF)),
                title: const Text('Камера',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF00AAFF)),
                title: const Text('Галерея',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white38),
          dropdownColor: const Color(0xFF1E1E2C),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: FeedViewModel.categories
              .where((c) => c != 'Все')
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Icon(icon, color: Colors.white38, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        ),
      ),
    );
  }
}
