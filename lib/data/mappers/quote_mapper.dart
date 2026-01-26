import 'package:dev_quotes/data/dto/quote_dto.dart';
import 'package:dev_quotes/data/models/quote_model.dart';
import 'package:dev_quotes/core/utils/string_utils.dart';

class QuoteMapper {
  static Quote toDomain(QuoteDto dto, {bool isFavorite = false}) {
    return Quote(
      id: dto.id,
      text: normalizeQuoteString(dto.text),
      author: normalizeQuoteString(dto.author),
      category: dto.category,
      userId: dto.userId,
      timestamp: dto.timestamp,
      isFavorite: isFavorite,
      isPublic: dto.isPublic,
      isDefault: dto.isDefault,
    );
  }

  static QuoteDto fromDomain(Quote model) {
    return QuoteDto(
      id: model.id,
      text: normalizeQuoteString(model.text),
      author: normalizeQuoteString(model.author),
      category: model.category,
      userId: model.userId,
      timestamp: model.timestamp,
      isPublic: model.isPublic,
      isDefault: model.isDefault,
    );
  }
}
