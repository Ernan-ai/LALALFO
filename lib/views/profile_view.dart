import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/feed_viewmodel.dart';
import 'auth_view.dart';
import 'support_bot_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return SafeArea(
      child: auth.isLoggedIn
          ? _LoggedInProfile(auth: auth)
          : _LoggedOutProfile(),
    );
  }
}

// ── Logged-out state ─────────────────────────────────────────────────────────
class _LoggedOutProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Профиль',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF2A2A3C),
                  child: const Icon(Icons.person_rounded,
                      size: 48, color: Colors.white24),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Войдите, чтобы управлять\nпрофилем и объявлениями',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AuthView())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AAFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Войти или зарегистрироваться',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logged-in state (customizable profile) ──────────────────────────────────
class _LoggedInProfile extends StatelessWidget {
  final AuthViewModel auth;
  const _LoggedInProfile({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Профиль',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // Avatar + name card
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _changeAvatar(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF2A2A3C),
                        backgroundImage: auth.avatarUrl.isNotEmpty
                            ? (kIsWeb || auth.avatarUrl.startsWith('http') || auth.avatarUrl.startsWith('blob:')
                                ? NetworkImage(auth.avatarUrl)
                                : FileImage(File(auth.avatarUrl))) as ImageProvider
                            : null,
                        child: auth.avatarUrl.isEmpty
                            ? const Icon(Icons.person_rounded,
                                size: 48, color: Colors.white24)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00AAFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  auth.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (auth.currentUser?.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    auth.currentUser!.email!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Edit profile fields
          _SectionTitle('Настройки профиля'),
          const SizedBox(height: 14),
          _ProfileField(
            icon: Icons.person_outline,
            label: 'Имя',
            value: auth.displayName,
            onTap: () => _editField(context, 'Имя', auth.displayName,
                (v) => auth.updateProfile(displayName: v)),
          ),
          _ProfileField(
            icon: Icons.phone_outlined,
            label: 'Телефон',
            value: auth.phone.isNotEmpty ? auth.phone : 'Не указан',
            onTap: () => _editField(context, 'Телефон', auth.phone,
                (v) => auth.updateProfile(phone: v)),
          ),
          _ProfileField(
            icon: Icons.location_city_outlined,
            label: 'Город',
            value: auth.city,
            onTap: () => _editField(context, 'Город', auth.city,
                (v) => auth.updateProfile(city: v)),
          ),

          const SizedBox(height: 28),

          // My listings
          _SectionTitle('Мои объявления'),
          const SizedBox(height: 14),
          _buildMyListings(context),
          const SizedBox(height: 28),

          // AI Support
          _SectionTitle('Поддержка'),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: const Color(0xFF12121F),
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF1A1A2E),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text('AI Поддержка',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  body: const SupportBotView(),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00AAFF), Color(0xFF7B61FF)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gemini AI Помощник',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Задайте любой вопрос',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white38)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.2)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Sign out
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => auth.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Выйти',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListings(BuildContext context) {
    final feed = context.watch<FeedViewModel>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    // Get all products, then filter by user. Access full unfiltered list.
    final myListings =
        feed.products.where((p) => p.userId == uid).toList();

    if (myListings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'У вас пока нет объявлений',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    return Column(
      children: myListings.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: p.imageUrl.isNotEmpty &&
                          (p.imageUrl.startsWith('/') ||
                              p.imageUrl.startsWith('C:') ||
                              p.imageUrl.startsWith('D:'))
                      ? Image.file(File(p.imageUrl), fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF2A2A3C),
                          child: const Icon(Icons.image,
                              color: Colors.white24, size: 24)),
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
                    const SizedBox(height: 4),
                    Text(p.formattedPrice,
                        style: TextStyle(
                            color: const Color(0xFF00AAFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2C),
                      title: const Text('Удалить объявление?',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Это действие нельзя отменить.',
                          style: TextStyle(color: Colors.white54)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    feed.deleteProduct(p.id);
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _changeAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null) return;

    String finalPath = picked.path;
    
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${const Uuid().v4()}.jpg';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      finalPath = savedFile.path;
    }

    await auth.updateProfile(avatarUrl: finalPath);
  }

  void _editField(BuildContext context, String label, String currentValue,
      Future<void> Function(String) onSave) {
    final ctrl = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12121F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Введите $label',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await onSave(ctrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AAFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Сохранить',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 18),
          ],
        ),
      ),
    );
  }
}
