import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SupportBotView extends StatefulWidget {
  const SupportBotView({super.key});

  @override
  State<SupportBotView> createState() => _SupportBotViewState();
}

class _SupportBotViewState extends State<SupportBotView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Привет! 👋 Я AI-помощник Lalafo на основе Gemini.\nЗадайте любой вопрос — я помогу!',
      isBot: true,
    ),
  ];
  bool _isTyping = false;
  bool _isPremium = false; // Paywall gate
  int _freeMessagesLeft = 3; // Free messages before paywall

  // Funny face images
  static const _faces = [
    'assets/faces/face1.jpg',
    'assets/faces/face2.jpg',
    'assets/faces/face3.jpg',
    'assets/faces/face4.jpg',
    'assets/faces/face5.jpg',
  ];

  // Gemini model
  static const _apiKey = 'AIzaSyAtJGIFsyRNxA_Frm3vmPohIVdghezITQg';
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final _rng = Random();

  String get _randomFace => _faces[_rng.nextInt(_faces.length)];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Ты — дружелюбный бот-помощник маркетплейса Lalafo.kg. '
        'Отвечай на русском языке. Помогай пользователям с вопросами о: '
        'размещении объявлений, покупке/продаже товаров, регистрации, '
        'безопасности сделок, категориях товаров, контактах поддержки. '
        'Будь кратким но информативным. Используй эмодзи где уместно. '
        'Если вопрос не связан с маркетплейсом — вежливо направь обратно к теме. '
        'Контакты поддержки: support@lalafo.kg, +996 312 123 456.',
      ),
    );
    _chat = _model.startChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Paywall dialog ──────────────────────────────────────────────────────
  void _showPaywall() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00AAFF).withValues(alpha: 0.15),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Funny rotating face
              ClipOval(
                child: Image.asset(
                  _randomFace,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shake(hz: 2, duration: 800.ms)
                  .then()
                  .shimmer(duration: 600.ms),
              const SizedBox(height: 16),
              const Text(
                '🔒 Бесплатные сообщения закончились!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Оплатите подписку, чтобы продолжить\nобщение с AI-помощником',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // QR Code
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/faces/qr_code.png',
                    width: 220,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              // Funny caption with random face
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      _faces[1],
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Салих ждёт оплату 👀',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipOval(
                    child: Image.asset(
                      _faces[3],
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Premium button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isPremium = true);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Premium активирован! Спасибо 🎉'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AAFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('✨ Я уже оплатил!',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Позже',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Check paywall
    if (!_isPremium && _freeMessagesLeft <= 0) {
      _showPaywall();
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _isTyping = true;
      if (!_isPremium) _freeMessagesLeft--;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply =
          response.text ?? 'Не удалось получить ответ. Попробуйте ещё раз.';

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(text: reply.trim(), isBot: true));
        });
        _scrollToBottom();

        // Show paywall teaser when 1 message left
        if (!_isPremium && _freeMessagesLeft == 0) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _showPaywall();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text:
                'Salikh',
            isBot: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header with funny face
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                // Bot avatar = random funny face
                ClipOval(
                  child: Image.asset(
                    _faces[2], // lenny-ish face
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .rotate(begin: -0.03, end: 0.03, duration: 1500.ms),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gemini AI Помощник',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _isPremium ? '✨ Premium' : '💬 $_freeMessagesLeft бесплатных',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPremium
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Funny faces parade in header
                ...List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ClipOval(
                      child: Image.asset(
                        _faces[i],
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 200))
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.3, end: 0);
                }),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[i]);
              },
            ),
          ),

          // Free messages banner
          if (!_isPremium && _freeMessagesLeft <= 1)
            GestureDetector(
              onTap: _showPaywall,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF4D6D).withValues(alpha: 0.2),
                      const Color(0xFF7B61FF).withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFFF4D6D).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        _faces[4],
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.9, end: 1.1, duration: 600.ms),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _freeMessagesLeft <= 0
                            ? '😢 Сообщения закончились! Нажмите для оплаты'
                            : '⚠️ Осталось $_freeMessagesLeft бесплатное сообщение',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.white30),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: _isPremium
                            ? 'Спросите что-нибудь... ✨'
                            : 'Спросите что-нибудь...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isTyping ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isTyping
                            ? [
                                const Color(0xFF444466),
                                const Color(0xFF333355),
                              ]
                            : [
                                const Color(0xFF00AAFF),
                                const Color(0xFF7B61FF),
                              ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            ClipOval(
              child: Image.asset(
                _faces[_rng.nextInt(_faces.length)],
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: msg.isBot
                    ? const Color(0xFF1E1E2C)
                    : const Color(0xFF00AAFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isBot ? 4 : 18),
                  bottomRight: Radius.circular(msg.isBot ? 18 : 4),
                ),
                border: msg.isBot
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.06))
                    : null,
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: Image.asset(
              _faces[0],
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.05, end: 0.05, duration: 400.ms),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AI думает ',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.3))),
                ...List.generate(3, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (c) => c.repeat(),
                          delay: Duration(milliseconds: i * 200))
                      .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms)
                      .then()
                      .scaleXY(begin: 1.0, end: 0.6, duration: 500.ms);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}
