import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/providers.dart';
import '../../../../../core/utils/type_defs.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../auth/controllers/auth_controller.dart';
import '../../../../auth/models/auth_state.dart';
import '../../../../quotes/presentation/providers/quote_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  
  bool _isEditing = false;
  bool _isLoading = false;

  // Cache initial values to check for changes
  String _initialName = '';
  String _initialBio = '';

  // Focus nodes for managing focus transitions
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();

    // Add listeners to focus nodes to update UI on focus changes
    _nameFocus.addListener(_onFocusChange);
    _bioFocus.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _loadUserData() {
    final authAsync = ref.read(authProvider);
    final authState = authAsync.value;
    if (authState is AuthAuthenticated) {
      _initialName = authState.user.username;
      _initialBio = authState.user.bio ?? '';
      
      _nameController.text = _initialName;
      _emailController.text = authState.user.email;
      _bioController.text = _initialBio;
    }
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _bioFocus.removeListener(_onFocusChange);
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)
        ),
        backgroundColor: isError ? AppColors.error : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authAsync = ref.read(authProvider);
      final authState = authAsync.value;
      if (authState is! AuthAuthenticated) {
        _showSnackBar('Not authenticated', isError: true);
        return;
      }

      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showSnackBar('Display Name cannot be empty', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      final updatedUser = User(
        id: authState.user.id,
        email: authState.user.email,
        username: name,
        photoUrl: authState.user.photoUrl,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        favoritesCount: authState.user.favoritesCount,
        quotesCount: authState.user.quotesCount,
      );

      final result = await profileRepo.updateProfile(updatedUser);

      if (result is Success) {
        ref.read(authProvider.notifier).updateUser(updatedUser);
        
        _initialName = updatedUser.username;
        _initialBio = updatedUser.bio ?? '';

        _showSnackBar('Profile updated successfully');
        
        if (mounted) {
           setState(() {
             _isEditing = false;
           });
           // Remove focus
           FocusScope.of(context).unfocus();
        }
      } else if (result is Error) {
        _showSnackBar(result.failure.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancelling: revert changes
        _nameController.text = _initialName;
        _bioController.text = _initialBio;
        FocusScope.of(context).unfocus();
      } else {
        // Find first editable field to focus
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _nameFocus.requestFocus();
        });
      }
      _isEditing = !_isEditing;
    });
  }

  bool _hasChanges() {
    return _nameController.text.trim() != _initialName ||
           _bioController.text.trim() != _initialBio;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    
    if (authAsync.value is! AuthAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F13),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    final user = (authAsync.value as AuthAuthenticated).user;
    
    // Watch real-time counts instead of relying on static fields
    final myQuotes = ref.watch(myQuotesProvider);
    final favorites = ref.watch(favoritesProvider);
    
    final quotesCountString = myQuotes.when(
      data: (quotes) => '${quotes.length}',
      loading: () => '...',
      error: (_, __) => '0',
    );
    
    final favoritesCountString = favorites.when(
      data: (quotes) => '${quotes.length}',
      loading: () => '...',
      error: (_, __) => '0',
    );

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Parallax Header
              SliverAppBar(
                expandedHeight: 280,
                collapsedHeight: 80,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0F0F13),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isEditing
                        ? IconButton(
                            key: const ValueKey('close'),
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: _toggleEdit,
                          )
                        : IconButton(
                            key: const ValueKey('edit'),
                            icon: const Icon(Icons.settings_outlined, color: Colors.white),
                            onPressed: _toggleEdit,
                          ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  centerTitle: true,
                  title: _isEditing ? null : Text(
                    user.username,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Deep Modern Gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color(0xFF1E1E28),
                              Color(0xFF0F0F13),
                              Color(0xFF0F0F13),
                            ],
                          ),
                        ),
                      ),
                      // Subtle Mesh Glow
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8B5CF6).withOpacity(0.05),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF8B5CF6).withOpacity(0.5),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F0F13),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: const Color(0xFF1A1A22),
                              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                 ? NetworkImage(user.photoUrl!)
                                 : null,
                              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                 ? Text(
                                     _getInitials(user.username),
                                     style: GoogleFonts.outfit(
                                       fontSize: 42,
                                       fontWeight: FontWeight.w800,
                                       color: const Color(0xFF8B5CF6),
                                       letterSpacing: -1,
                                     ),
                                   )
                                 : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    children: [
                      // Premium Stats Card
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatItem('Quotes', quotesCountString)),
                            Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
                            Expanded(child: _buildStatItem('Favorites', favoritesCountString)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      _buildSectionHeader('Account Details'),
                      const SizedBox(height: 24),

                      // Grouped Minimal Form Surface
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161D),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Column(
                          children: [
                            _buildCustomField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              enabled: _isEditing,
                              focusNode: _nameFocus,
                              isFirst: true,
                            ),
                            Divider(height: 1, color: Colors.white.withOpacity(0.03), indent: 64),
                            _buildCustomField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.alternate_email_rounded,
                              enabled: false,
                              showLockIcon: true,
                            ),
                            Divider(height: 1, color: Colors.white.withOpacity(0.03), indent: 64),
                            _buildCustomField(
                              controller: _bioController,
                              label: 'Short Biography',
                              icon: Icons.notes_rounded,
                              enabled: _isEditing,
                              focusNode: _bioFocus,
                              isLast: true,
                              isMultiLine: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      
                      if (!_isEditing) ...[
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
                          label: Text(
                            'Privacy & Security Settings',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Pinned bottom actions for editing mode
          if (_isEditing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F0F13).withOpacity(0),
                      const Color(0xFF0F0F13),
                    ],
                    stops: const [0, 0.4],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : _toggleEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          foregroundColor: Colors.white70,
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (_hasChanges() && !_isLoading) ? _saveProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          disabledBackgroundColor: const Color(0xFF252530),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.inter(
                                  color: _hasChanges() ? Colors.white : Colors.white24,
                                  fontWeight: FontWeight.w700,
                                ),
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
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF8B5CF6),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool isMultiLine = false,
    bool showLockIcon = false,
    FocusNode? focusNode,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isMultiLine ? 16 : 0),
            child: Icon(
              icon,
              color: enabled ? Colors.white24 : Colors.white10,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8B5CF6).withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  focusNode: focusNode,
                  maxLines: isMultiLine ? null : 1,
                  minLines: 1,
                  onTapOutside: (_) => focusNode?.unfocus(),
                  cursorColor: const Color(0xFF8B5CF6),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(enabled ? 1.0 : 0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (showLockIcon && !enabled)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white.withOpacity(0.05)),
            ),
        ],
      ),
    );
  }
}
