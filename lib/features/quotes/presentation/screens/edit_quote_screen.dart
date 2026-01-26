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
              readOnly: true,
            ),
            const SizedBox(height: 24),
            _buildLabel('Category'),
            const SizedBox(height: 8),
            _buildCategorySelector(categoriesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(AsyncValue<List<String>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => GestureDetector(
        onTap: () => _showCategoryPicker(context, categories),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory ?? 'Select Category',
                style: GoogleFonts.inter(
                  color: _selectedCategory != null
                      ? Colors.white
                      : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white),
            ],
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
      error: (err, stack) => Text(
        'Failed to load categories',
        style: GoogleFonts.inter(color: AppColors.error),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF16161D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Category',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B5CF6).withOpacity(0.2)
                              : const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF8B5CF6), size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly 
            ? const Color(0xFF1E1E24).withOpacity(0.5) 
            : const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        style: GoogleFonts.inter(
          color: readOnly ? Colors.grey[400] : Colors.white, 
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: readOnly 
              ? InputBorder.none 
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                ),
        ),
      ),
    );
  }
}
