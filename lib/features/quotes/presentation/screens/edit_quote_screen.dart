import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/utils/type_defs.dart';
import '../../../../data/models/quote_model.dart';
import '../providers/quote_provider.dart';

class EditQuoteScreen extends ConsumerStatefulWidget {
  final Quote quote;

  const EditQuoteScreen({super.key, required this.quote});

  @override
  ConsumerState<EditQuoteScreen> createState() => _EditQuoteScreenState();
}

class _EditQuoteScreenState extends ConsumerState<EditQuoteScreen> {
  late TextEditingController _textController;
  late TextEditingController _authorController;
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: normalizeQuoteString(widget.quote.text));
    _authorController = TextEditingController(text: normalizeQuoteString(widget.quote.author));
    _selectedCategory = widget.quote.category;
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveQuote() async {
    if (_textController.text.trim().isEmpty) {
      _showSnackBar('Quote text cannot be empty', isError: true);
      return;
    }
    if (_authorController.text.trim().isEmpty) {
      _showSnackBar('Author cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedQuote = Quote(
        id: widget.quote.id,
        text: _textController.text.trim(),
        author: _authorController.text.trim(),
        category: _selectedCategory ?? widget.quote.category,
        userId: widget.quote.userId,
        timestamp: widget.quote.timestamp,
        isFavorite: widget.quote.isFavorite,
      );

      final updateNotifier = ref.read(updateQuoteProvider.notifier);
      await updateNotifier.updateQuote(updatedQuote);

      final state = ref.read(updateQuoteProvider);
      
      if (mounted) {
        if (state.hasError) {
           _showSnackBar('Failed to update quote', isError: true);
        } else {
           _showSnackBar('Quote updated successfully');
           context.pop(); // Go back
        }
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Edit Quote',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveQuote,
            child: Text(
              'Save',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Quote Text'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _textController,
              hint: 'Enter your quote...',
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            _buildLabel('Author'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _authorController,
              hint: 'Author name',
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            _buildLabel('Category'),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categories.contains(_selectedCategory) ? _selectedCategory : null,
                      hint: Text(
                        'Select Category',
                        style: GoogleFonts.inter(color: Colors.grey[500]),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E24),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      items: categories.toSet().map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(color: Color(0xFF8B5CF6)),
              ),
              error: (err, stack) => Text(
                'Failed to load categories',
                style: GoogleFonts.inter(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
          ),
        ),
      ),
    );
  }
}
