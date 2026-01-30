import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dev_quotes/core/error/failures.dart';
import 'package:dev_quotes/data/dto/category_dto.dart';
import 'package:dev_quotes/data/dto/quote_dto.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';

abstract class FirestoreDataSource {
  Future<void> saveUser(UserDto user);
  Future<UserDto?> getUser(String uid);
  Future<void> updateUser(UserDto user);

  Future<QuoteDto> getRandomQuote();
  Future<QuoteDto?> getQuoteById(String id);
  Future<List<QuoteDto>> getQuotesByIds(List<String> ids);
  Future<List<QuoteDto>> getQuotesByCategory(String categoryId);
  Future<List<CategoryDto>> getCategories();
  Future<List<QuoteDto>> searchQuotes(String query, {String? author, String? category});
  Future<String> addQuote(QuoteDto quote);
  Future<void> updateQuote(QuoteDto quote);
  Future<void> deleteQuote(String quoteId, String currentUserId);
  Stream<List<QuoteDto>> getUserQuotes(String userId);
  Stream<List<QuoteDto>> getPublicQuotes();
  Stream<List<QuoteDto>> getQuoteFeed(String userId, bool showPublic);

  Stream<List<String>> getFavoritesIds(String userId);
  Future<void> addFavorite(String userId, String quoteId);
  Future<void> removeFavorite(String userId, String quoteId);
  Future<List<QuoteDto>> getFavorites(String userId);

  // User preferences
  Future<bool> getUserPreference(String userId, String key, bool defaultValue);
  Future<void> setUserPreference(String userId, String key, bool value);
  Future<void> updateUserFCMToken(String userId, String token);

  // OFFLINE-FIRST: Methods for sync operations
  Future<void> addQuoteFromJson(Map<String, dynamic> data);
  Future<void> updateQuoteFromJson(String quoteId, Map<String, dynamic> data);
  Future<void> saveUserFromJson(Map<String, dynamic> data);
}

class FirestoreDataSourceImpl implements FirestoreDataSource {
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  FirestoreDataSourceImpl({
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  /// MEDIUM SECURITY FIX: Check if device is online before network operations
  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// MEDIUM SECURITY FIX: Wrapper for operations that require connectivity
  Future<T> _withConnectivityCheck<T>(Future<T> Function() operation) async {
    if (!await _isOnline()) {
      throw const CacheFailure('No internet connection. Please check your network and try again.');
    }
    return operation();
  }

  @override
  Future<void> saveUser(UserDto user) async {
    return _withConnectivityCheck(() async {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    });
  }

  @override
  Future<UserDto?> getUser(String uid) async {
    return _withConnectivityCheck(() async {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserDto.fromFirestore(doc);
      }
      return null;
    });
  }

  @override
  Future<void> updateUser(UserDto user) async {
    return _withConnectivityCheck(() async {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    });
  }

  @override
  Future<QuoteDto> getRandomQuote() async {
    // SECURITY FIX: Only fetch public/default quotes, not private ones
    // This prevents exposing private quotes from other users
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
    if (doc.exists) {
      return QuoteDto.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<List<QuoteDto>> getQuotesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn is limited to 10. If more, we need to batch or loop.
    // For simplicity, we'll loop or chunk.
    // Or better, if we store quote data in favorites, we don't need this.
    // But assuming we fetch fresh data:
    List<QuoteDto> quotes = [];
    // Chunking 10
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);
      final query = await _firestore
          .collection('quotes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      quotes.addAll(query.docs.map((doc) => QuoteDto.fromFirestore(doc)));
    }
    return quotes;
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
  Future<List<CategoryDto>> getCategories() async {
    final query = await _firestore.collection('categories').get();
    return query.docs.map((doc) => CategoryDto.fromFirestore(doc)).toList();
  }

  @override
  Future<List<QuoteDto>> searchQuotes(String queryText, {String? author, String? category}) async {
    // SECURITY FIX: Sanitize and validate input
    final sanitized = queryText.trim();
    
    // Validate length
    if (sanitized.isEmpty || sanitized.length > 100) {
      return [];
    }
    
    // Remove control characters that could affect query
    final cleanQuery = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    if (cleanQuery.isEmpty) {
      return [];
    }

    final query = await _firestore
        .collection('quotes')
        .where('quoteText', isGreaterThanOrEqualTo: cleanQuery)
        .where('quoteText', isLessThan: cleanQuery + '\uf8ff') // Unicode-safe
        .limit(50) // SECURITY FIX: Add limit to prevent overfetching
        .get();

    return query.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
  }

  @override
  Future<String> addQuote(QuoteDto quote) async {
    // If ID is empty, generate one
    var docRef = _firestore
        .collection('quotes')
        .doc(quote.id.isEmpty ? null : quote.id);
    // Update DTO with new ID if generated
    // But DTO is immutable. We should probably pass a DTO without ID and let Firestore generate,
    // then return the ID. But for now, we assume ID is handled or we set it.
    // Let's just set the data.
    await docRef.set(quote.toFirestore());
    
    // Increment user's quotes count
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
  Stream<List<QuoteDto>> getUserQuotes(String userId) {
    return _firestore
        .collection('quotes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final quotes = snapshot.docs
              .map((doc) => QuoteDto.fromFirestore(doc))
              .toList();
          // Sort by timestamp descending in memory
          quotes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return quotes;
        });
  }

  @override
  Stream<List<QuoteDto>> getPublicQuotes() {
    // Legacy support, or for unauthenticated
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
      // Show: Public + Default + My Quotes
      // Logic: (isPublic == true) OR (isDefault == true) OR (userId == currentUserId)
      query = query.where(Filter.or(
        Filter('isPublic', isEqualTo: true),
        Filter('isDefault', isEqualTo: true),
        Filter('userId', isEqualTo: userId),
      ));
    } else {
      // Show: My Quotes + Default (Strictly NO other public quotes)
      // Logic: (userId == currentUserId) OR (isDefault == true)
      query = query.where(Filter.or(
        Filter('userId', isEqualTo: userId),
        Filter('isDefault', isEqualTo: true),
      ));
    }

    return query
        .limit(50) // Reasonable limit for stream
        .snapshots()
        .map((snapshot) {
      final quotes = snapshot.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
      // Sort in-memory to avoid index requirement for complex OR filters
      quotes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return quotes;
    });
  }

  @override
  Future<bool> getUserPreference(
    String userId,
    String key,
    bool defaultValue,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['preferences'] != null) {
          final prefs = data['preferences'] as Map<String, dynamic>;
          return prefs[key] as bool? ?? defaultValue;
        }
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  Future<void> setUserPreference(String userId, String key, bool value) async {
    await _firestore.collection('users').doc(userId).update({
      'preferences.$key': value,
    });
  }

  @override
  Future<void> updateUserFCMToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
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

    // Use transaction to prevent race conditions
    await _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);
      
      if (favoriteDoc.exists) {
        // Already favorited, no-op
        return;
      }
      
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

    // Use transaction to prevent race conditions
    await _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);
      
      if (!favoriteDoc.exists) {
        // Not favorited, no-op
        return;
      }
      
      transaction.delete(favoriteRef);
      transaction.update(userRef, {'favoritesCount': FieldValue.increment(-1)});
    });
  }

  @override
  Future<void> deleteQuote(String quoteId, String currentUserId) async {
    final docRef = _firestore.collection('quotes').doc(quoteId);
    
    // SECURITY FIX: Use transaction to verify ownership before deletion
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (!doc.exists) {
        throw Exception('Quote not found');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final ownerId = data['userId'] as String?;
      final isDefault = data['isDefault'] as bool? ?? false;
      
      // Verify ownership
      if (ownerId != currentUserId) {
        throw Exception('Not authorized to delete this quote');
      }
      
      // Prevent deleting system/default quotes
      if (isDefault) {
        throw Exception('Cannot delete system quotes');
      }
      
      transaction.delete(docRef);
      
      if (ownerId != null && ownerId.isNotEmpty) {
        transaction.update(
          _firestore.collection('users').doc(ownerId),
          {'quotesCount': FieldValue.increment(-1)},
        );
      }
    });
  }

  // OFFLINE-FIRST: Methods for sync operations
  @override
  Future<void> addQuoteFromJson(Map<String, dynamic> data) async {
    final quoteId = data['id'] as String?;
    if (quoteId == null) {
      throw ArgumentError('Quote ID is required');
    }
    await _firestore.collection('quotes').doc(quoteId).set(data);
  }

  @override
  Future<void> updateQuoteFromJson(String quoteId, Map<String, dynamic> data) async {
    await _firestore.collection('quotes').doc(quoteId).update(data);
  }

  @override
  Future<void> saveUserFromJson(Map<String, dynamic> data) async {
    final userId = data['id'] as String?;
    if (userId == null) {
      throw ArgumentError('User ID is required');
    }
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
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
    
    final quotesSnapshot = await _firestore
        .collection('quotes')
        .where(FieldPath.documentId, whereIn: quoteIds)
        .get();
    
    return quotesSnapshot.docs.map((doc) => QuoteDto.fromFirestore(doc)).toList();
  }
}
