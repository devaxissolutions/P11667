String normalizeQuoteString(String? value) {
  if (value == null) return '';
  // Remove zero-width whitespace characters and trim
  final cleaned = value.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
  return cleaned.trim();
}
