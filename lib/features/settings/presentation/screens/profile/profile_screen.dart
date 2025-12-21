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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
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
       return Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F13),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
       );
    }

    final user = (authAsync.value as AuthAuthenticated).user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isEditing ? 'Edit Profile' : 'Profile',
            key: ValueKey(_isEditing),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: _isEditing
                ? IconButton(
                    key: const ValueKey('close_btn'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: _toggleEdit,
                    tooltip: 'Cancel Editing',
                  )
                : IconButton(
                    key: const ValueKey('edit_btn'),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                    onPressed: _toggleEdit,
                    tooltip: 'Edit Profile',
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Section with Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.25),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Gradient Border Container
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6),
                              const Color(0xFF8B5CF6).withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF16161D),
                          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                             ? NetworkImage(user.photoUrl!)
                             : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                             ? Text(
                                 _getInitials(user.username),
                                 style: GoogleFonts.outfit(
                                   fontSize: 34,
                                   fontWeight: FontWeight.bold,
                                   color: const Color(0xFF8B5CF6),
                                   letterSpacing: 1,
                                 ),
                               )
                             : null,
                        ),
                      ),
                      if (_isEditing)
                         Positioned(
                           bottom: 0,
                           right: 0,
                           child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F0F13), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded, 
                                size: 16, 
                                color: Colors.white,
                              ),
                           ),
                         ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Professional Stats Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Quotes', '${user.quotesCount}'),
                          VerticalDivider(
                            color: Colors.white.withOpacity(0.1),
                            thickness: 1,
                            width: 1,
                            indent: 4,
                            endIndent: 4,
                          ),
                          _buildStatItem('Favorites', '${user.favoritesCount}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form Fields
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 16),
                  
                  _buildCustomField(
                    controller: _nameController,
                    label: 'Display Name',
                    icon: Icons.person_outline_rounded,
                    enabled: _isEditing,
                    focusNode: _nameFocus,
                  ),

                  const SizedBox(height: 20),

                  _buildCustomField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    enabled: false, // Always read-only
                    showLockIcon: true,
                  ),

                  const SizedBox(height: 20),

                  _buildCustomField(
                    controller: _bioController,
                    label: 'Biography',
                    icon: Icons.edit_note_rounded,
                    enabled: _isEditing,
                    focusNode: _bioFocus,
                    isMultiLine: true,
                  ),
                  
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: AnimatedSlide(
        offset: _isEditing ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.4),
                 blurRadius: 16,
                 offset: const Offset(0, -4),
               )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _toggleEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_hasChanges() && !_isLoading) ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor: const Color(0xFF1E1E24),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: (_hasChanges()) ? Colors.white : Colors.grey[500],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // A completely custom field widget for perfect control over layout and states
  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool isMultiLine = false,
    bool showLockIcon = false,
    FocusNode? focusNode,
  }) {
    // In read-only mode, we want a very clean look: similar to text.
    // In edit mode, we want a clearly defined input field.
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: enabled ? const Color(0xFF8B5CF6) : Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: enabled 
                ? const Color(0xFF16161D) // Slightly darker than surface for input depth
                : Colors.transparent,     // Transparent when reading
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled 
                  ? const Color(0xFF8B5CF6).withOpacity(0.3) // Subtle focused/edit border
                  : Colors.white.withOpacity(0.08),          // Very faint border for structure when reading
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 16, 
                  right: 16, 
                  top: isMultiLine ? 16 : 16,
                  bottom: isMultiLine ? 16 : 16
                ),
                child: Icon(
                  icon,
                  color: enabled ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 16, 
                    top: isMultiLine ? 6 : 0, 
                    bottom: isMultiLine ? 6 : 0
                  ),
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    focusNode: focusNode,
                    maxLines: isMultiLine ? 4 : 1,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500, // Medium weight for better readability
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      // Remove all default borders as we manage them in the Container
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                      hintText: 'Enter $label...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
              if (showLockIcon && !enabled)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white.withOpacity(0.2),
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
