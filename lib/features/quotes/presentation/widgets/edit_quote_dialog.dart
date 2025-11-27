import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../data/models/quote_model.dart';
import '../../../../core/utils/string_utils.dart';
import '../providers/quote_provider.dart';

class EditQuoteDialog extends ConsumerStatefulWidget {
  final Quote quote;

  const EditQuoteDialog({super.key, required this.quote});

  @override
  ConsumerState<EditQuoteDialog> createState() => _EditQuoteDialogState();
}

class _EditQuoteDialogState extends ConsumerState<EditQuoteDialog> {
  late TextEditingController _textController;
  late TextEditingController _authorController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: normalizeQuoteString(widget.quote.text),
    );
    _authorController = TextEditingController(
      text: normalizeQuoteString(widget.quote.author),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _saveQuote() async {
    if (_textController.text.trim().isEmpty ||
        _authorController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final updatedQuote = Quote(
      id: widget.quote.id,
      text: _textController.text.trim(),
      author: _authorController.text.trim(),
      category: widget.quote.category,
      userId: widget.quote.userId,
      timestamp: widget.quote.timestamp,
      isFavorite: widget.quote.isFavorite,
    );

    final updateNotifier = ref.read(updateQuoteProvider.notifier);
    await updateNotifier.updateQuote(updatedQuote);

    final state = ref.read(updateQuoteProvider);
    if (state.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quote: ${state.error}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote updated successfully')),
        );
        Navigator.of(context).pop();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Quote',
              style: AppTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Quote Text',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Author',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
