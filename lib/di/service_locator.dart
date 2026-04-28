import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dev_quotes/data/datasources/auth_remote_data_source.dart';
import 'package:dev_quotes/data/datasources/quote_data_source.dart';
import 'package:dev_quotes/data/datasources/user_data_source.dart';
import 'package:dev_quotes/data/datasources/category_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/datasources/local/hive_local_data_source.dart';
import 'package:dev_quotes/data/datasources/local/sync_queue_local_data_source.dart';
import 'package:dev_quotes/data/repositories/impl/auth_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/category_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/profile_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/quote_repository_impl.dart';
import 'package:dev_quotes/domain/repositories/auth_repository.dart';
import 'package:dev_quotes/domain/repositories/category_repository.dart';
import 'package:dev_quotes/domain/repositories/profile_repository.dart';
import 'package:dev_quotes/domain/repositories/quote_repository.dart';
import 'package:dev_quotes/domain/use_cases/quotes/get_quote_feed_use_case.dart';
import 'package:dev_quotes/domain/use_cases/quotes/search_quotes_use_case.dart';
import 'package:dev_quotes/domain/use_cases/quotes/toggle_favorite_use_case.dart';
import 'package:dev_quotes/data/services/offline/offline_sync_service.dart';
import 'package:dev_quotes/data/services/offline/sync_operation.dart';
import 'package:dev_quotes/data/services/offline/handlers/quote_sync_handler.dart';
import 'package:dev_quotes/data/services/offline/handlers/user_sync_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_quotes/core/services/update_service.dart';
import 'package:dev_quotes/core/services/notifications/notification_service.dart';
import 'package:dev_quotes/core/services/rate_limit_service.dart';
import 'package:dev_quotes/core/services/session_service.dart';
import 'package:dev_quotes/core/services/circuit_breaker.dart';

// External Services
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final onboardingCompletedProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('onboarding_completed') ?? false;
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged;
});

final circuitBreakerProvider = Provider<CircuitBreaker>((ref) {
  return CircuitBreaker(
    name: 'offline_sync',
    failureThreshold: 3,
    resetTimeout: const Duration(minutes: 1),
  );
});

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final quoteDataSourceProvider = Provider<QuoteDataSource>((ref) {
  return QuoteDataSourceImpl(ref.watch(firestoreProvider));
});

final userDataSourceProvider = Provider<UserDataSource>((ref) {
  return UserDataSourceImpl(ref.watch(firestoreProvider));
});

final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
  return CategoryDataSourceImpl(ref.watch(firestoreProvider));
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

// OFFLINE-FIRST: Hive local data source
final hiveLocalDataSourceProvider = Provider<HiveLocalDataSource>((ref) {
  return HiveLocalDataSource();
});

// OFFLINE-FIRST: Sync queue local data source
final syncQueueLocalDataSourceProvider = Provider<SyncQueueLocalDataSource>((ref) {
  return SyncQueueLocalDataSource();
});

// OFFLINE-FIRST: Offline sync service
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final handlers = {
    SyncOperationType.createQuote: QuoteSyncHandler(ref.watch(quoteDataSourceProvider)),
    SyncOperationType.updateQuote: QuoteSyncHandler(ref.watch(quoteDataSourceProvider)),
    SyncOperationType.deleteQuote: QuoteSyncHandler(ref.watch(quoteDataSourceProvider)),
    SyncOperationType.toggleFavorite: QuoteSyncHandler(ref.watch(quoteDataSourceProvider)),
    SyncOperationType.updateProfile: UserSyncHandler(ref.watch(userDataSourceProvider)),
  };

  return OfflineSyncService(
    syncQueue: ref.watch(syncQueueLocalDataSourceProvider),
    circuitBreaker: ref.watch(circuitBreakerProvider),
    handlers: handlers,
  );
});

// Repositories
final rateLimitServiceProvider = Provider<RateLimitService>((ref) {
  return RateLimitService(ref.watch(sharedPreferencesProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authDataSource: ref.watch(authRemoteDataSourceProvider),
    userDataSource: ref.watch(userDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
    rateLimitService: ref.watch(rateLimitServiceProvider),
  );
});

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepositoryImpl(
    quoteDataSource: ref.watch(quoteDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
    syncService: ref.watch(offlineSyncServiceProvider),
    rateLimitService: ref.watch(rateLimitServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    userDataSource: ref.watch(userDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    categoryDataSource: ref.watch(categoryDataSourceProvider),
  );
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService.instance;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    messaging: ref.watch(firebaseMessagingProvider),
    auth: ref.watch(firebaseAuthProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(auth: ref.watch(firebaseAuthProvider));
});

// Use Cases
final getQuoteFeedUseCaseProvider = Provider<GetQuoteFeedUseCase>((ref) {
  return GetQuoteFeedUseCase(ref.watch(quoteRepositoryProvider));
});

final searchQuotesUseCaseProvider = Provider<SearchQuotesUseCase>((ref) {
  return SearchQuotesUseCase(ref.watch(quoteRepositoryProvider));
});

final toggleFavoriteUseCaseProvider = Provider<ToggleFavoriteUseCase>((ref) {
  return ToggleFavoriteUseCase(ref.watch(quoteRepositoryProvider));
});
