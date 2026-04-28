import 'package:dev_quotes/core/utils/type_defs.dart';
import 'package:dev_quotes/domain/repositories/quote_repository.dart';

class ToggleFavoriteUseCase {
  final QuoteRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  Future<Result<void>> execute(String quoteId, String userId, bool currentlyFavorite) async {
    if (currentlyFavorite) {
      return await _repository.removeFavorite(quoteId, userId);
    } else {
      return await _repository.addFavorite(quoteId, userId);
    }
  }
}
