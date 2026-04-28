import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:dev_quotes/di/service_locator.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/models/auth_state.dart';
import '../../../quotes/presentation/providers/quote_provider.dart';
import 'package:dev_quotes/core/widgets/quote_card.dart';
import 'package:dev_quotes/domain/entities/quote.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(quotesProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final authAsync = ref.watch(authProvider);

    final isOffline = connectivityAsync.maybeWhen(
      data: (results) => results.every((r) => r == ConnectivityResult.none),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Background Glow decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                if (isOffline) _buildOfflineBar(),
                
                // Header
                _buildHeader(context, authAsync),
                
                Expanded(
                  child: quotesAsync.when(
                    data: (quotes) {
                      if (quotes.isEmpty) return _buildEmptyState();
                      return _HomeContent(quotes: quotes);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.orangeAccent.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 8),
          Text(
            "Offline Mode",
            style: GoogleFonts.inter(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<AuthState> authAsync) {
    String greeting = "Hello, Wise Soul";
    String? avatarUrl;

    if (authAsync.value is AuthAuthenticated) {
      final user = (authAsync.value as AuthAuthenticated).user;
      greeting = "Morning, ${user.username}";
      avatarUrl = user.photoUrl;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Ready for your daily wisdom?",
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1E1E24),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null 
                  ? const Icon(Icons.person_rounded, color: Colors.white70)
                  : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.format_quote_rounded, color: Colors.grey[800], size: 80),
          const SizedBox(height: 16),
          Text(
            "No quotes today",
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final List<Quote> quotes;
  const _HomeContent({required this.quotes});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.quotes.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final quote = widget.quotes[index];
              return ListenableBuilder(
                listenable: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.hasContentDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: CoreQuoteCard(
                          quote: quote,
                          style: QuoteCardStyle.hero,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _ActionBar(controller: _pageController, quotes: widget.quotes),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}



class _ActionBar extends ConsumerWidget {
  final PageController controller;
  final List<Quote> quotes;
  const _ActionBar({required this.controller, required this.quotes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        int index = 0;
        if (controller.hasClients) {
          index = controller.page?.round() ?? 0;
        }
        if (index >= quotes.length) index = quotes.length - 1;
        final quote = quotes[index];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withOpacity(0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: quote.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: quote.isFavorite ? const Color(0xFFEF4444) : Colors.white70,
                onTap: () => ref.read(quotesProvider.notifier).toggleFavorite(quote),
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                color: Colors.white70,
                onTap: () {
                  Share.share(
                    '"${normalizeQuoteString(quote.text)}" - ${normalizeQuoteString(quote.author)}',
                  );
                },
              ),
              _ActionButton(
                icon: Icons.refresh_rounded,
                color: Colors.white70,
                onTap: () {
                  ref.read(quotesProvider.notifier).shuffle();
                  controller.animateToPage(
                    0, 
                    duration: const Duration(milliseconds: 500), 
                    curve: Curves.easeInOut
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
