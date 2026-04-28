import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_quotes/data/dto/quote_dto.dart';

abstract class QuoteDataSource {
  Future<QuoteDto> getRandomQuote();
  Future<QuoteDto?> getQuoteById(String id);
  Future<List<QuoteDto>> getQuotesByIds(List<String> ids);
  Future<List<QuoteDto>> getQuotesByCategory(String categoryId);
  Future<List<QuoteDto>> searchQuotes(String query, {String? author, String? category});
  Future<String> addQuote(QuoteDto quote);
  Future<void> updateQuote(QuoteDto quote);
  Future<void> deleteQuote(String quoteId, String currentUserId);
  Stream<List<QuoteDto>> getUserQuotes(String userId);
  Stream<List<QuoteDto>> getPublicQuotes();
  Stream<List<QuoteDto>> getQuoteFeed(String userId, bool showPublic);
  
  // Favorites
  Stream<List<String>> getFavoritesIds(String userId);
  Future<void> addFavorite(String userId, String quoteId);
  Future<void> removeFavorite(String userId, String quoteId);
  Future<List<QuoteDto>> getFavorites(String userId);

  // Sync
  Future<void> addQuoteFromJson(Map<String, dynamic> data);
  Future<void> updateQuoteFromJson(String quoteId, Map<String, dynamic> data);
}

class QuoteDataSourceImpl implements QuoteDataSource {
  final FirebaseFirestore _firestore;

  QuoteDataSourceImpl(this._firestore);

  @override
  Future<QuoteDto> getRandomQuote() async {
    final query = await _firestore
        .collection('quotes')
        .where(Filter.or(
          Filter('isPublic', isEqualTo: true),
          Filter('isDefault', isEqualTo: true),
        ))
        .limit(50)
        .get();
    
    if (query.docs.isEmpty) throw Exception('No quotes found');
    final docs = List.from(query.docs);
    docs.shuffle();
    return QuoteDto.fromFirestore(docs.first);
  }

  @override
  Future<QuoteDto?> getQuoteById(String id) async {
    final doc = await _firestore.collection('quotes').doc(id).get();
    if (doc.exists) return QuoteDto.fromFirestore(doc);
    return null;
  }

  @override
  Future<List<QuoteDto>> getQuotesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    // Using individual gets instead of whereIn to bypass "query-safe" rule requirements
    // and handle deleted or private quotes more gracefully.
    final futures = ids.map((id) => _firestore.collection('quotes').doc(id).get());
    final snapshots = await Future.wait(futures);
    
    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => QuoteDto.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<QuoteDto>> getQuotesByCategory(String categoryId) async {
    final query = await _firestore
        .collection('quotes')
        .where('category', isEqualTo: categoryId)
        .get();
    return query.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
  }

  @override
  Future<List<QuoteDto>> searchQuotes(String queryText, {String? author, String? category}) async {
    final sanitized = queryText.trim();
    if (sanitized.isEmpty || sanitized.length > 100) return [];
    
    final cleanQuery = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    if (cleanQuery.isEmpty) return [];

    final query = await _firestore
        .collection('quotes')
        .where('quoteText', isGreaterThanOrEqualTo: cleanQuery)
        .where('quoteText', isLessThan: '$cleanQuery\uf8ff')
        .limit(50)
        .get();

    return query.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
  }

  @override
  Future<String> addQuote(QuoteDto quote) async {
    var docRef = _firestore
        .collection('quotes')
        .doc(quote.id.isEmpty ? null : quote.id);
    await docRef.set(quote.toFirestore());
    
    if (quote.userId.isNotEmpty) {
      await _firestore.collection('users').doc(quote.userId).update({
        'quotesCount': FieldValue.increment(1),
      });
    }
    return docRef.id;
  }

  @override
  Future<void> updateQuote(QuoteDto quote) async {
    await _firestore
        .collection('quotes')
        .doc(quote.id)
        .update(quote.toFirestore());
  }

  @override
  Future<void> deleteQuote(String quoteId, String currentUserId) async {
    final docRef = _firestore.collection('quotes').doc(quoteId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) throw Exception('Quote not found');
      
      final data = doc.data() as Map<String, dynamic>;
      final ownerId = data['userId'] as String?;
      if (ownerId != currentUserId) throw Exception('Not authorized');
      
      transaction.delete(docRef);
      if (ownerId != null && ownerId.isNotEmpty) {
        transaction.update(
          _firestore.collection('users').doc(ownerId),
          {'quotesCount': FieldValue.increment(-1)},
        );
      }
    });
  }

  @override
  Stream<List<QuoteDto>> getUserQuotes(String userId) {
    return _firestore
        .collection('quotes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final quotes = snapshot.docs
              .map((doc) => QuoteDto.fromFirestore(doc))
              .toList();
          quotes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return quotes;
        });
  }

  @override
  Stream<List<QuoteDto>> getPublicQuotes() {
    return _firestore
        .collection('quotes')
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => QuoteDto.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Stream<List<QuoteDto>> getQuoteFeed(String userId, bool showPublic) {
    Query query = _firestore.collection('quotes');
    if (showPublic) {
      query = query.where(Filter.or(
        Filter('isPublic', isEqualTo: true),
        Filter('isDefault', isEqualTo: true),
        Filter('userId', isEqualTo: userId),
      ));
    } else {
      query = query.where(Filter.or(
        Filter('userId', isEqualTo: userId),
        Filter('isDefault', isEqualTo: true),
      ));
    }
    return query
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final quotes = snapshot.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
      quotes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return quotes;
    });
  }

  @override
  Stream<List<String>> getFavoritesIds(String userId) {
    return _firestore
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  @override
  Future<void> addFavorite(String userId, String quoteId) async {
    final favoriteRef = _firestore
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .doc(quoteId);
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);
      if (favoriteDoc.exists) return;
      transaction.set(favoriteRef, {'addedAt': FieldValue.serverTimestamp()});
      transaction.update(userRef, {'favoritesCount': FieldValue.increment(1)});
    });
  }

  @override
  Future<void> removeFavorite(String userId, String quoteId) async {
    final favoriteRef = _firestore
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .doc(quoteId);
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);
      if (!favoriteDoc.exists) return;
      transaction.delete(favoriteRef);
      transaction.update(userRef, {'favoritesCount': FieldValue.increment(-1)});
    });
  }

  @override
  Future<List<QuoteDto>> getFavorites(String userId) async {
    final favoritesSnapshot = await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .get();
    final quoteIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
    if (quoteIds.isEmpty) return [];
    
    // Using individual gets instead of whereIn for consistency and rule compatibility
    final futures = quoteIds.map((id) => _firestore.collection('quotes').doc(id).get());
    final snapshots = await Future.wait(futures);
    
    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => QuoteDto.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> addQuoteFromJson(Map<String, dynamic> data) async {
    final quoteId = data['id'] as String;
    await _firestore.collection('quotes').doc(quoteId).set(data);
  }

  @override
  Future<void> updateQuoteFromJson(String quoteId, Map<String, dynamic> data) async {
    await _firestore.collection('quotes').doc(quoteId).update(data);
  }
}
