import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dev_quotes/data/datasources/auth_remote_data_source.dart';
import 'package:dev_quotes/data/datasources/firestore_data_source.dart';
import 'package:dev_quotes/data/datasources/local_data_source.dart';
import 'package:dev_quotes/data/repositories/impl/auth_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/category_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/profile_repository_impl.dart';
import 'package:dev_quotes/data/repositories/impl/quote_repository_impl.dart';
import 'package:dev_quotes/data/repositories/interfaces/auth_repository.dart';
import 'package:dev_quotes/data/repositories/interfaces/category_repository.dart';
import 'package:dev_quotes/data/repositories/interfaces/profile_repository.dart';
import 'package:dev_quotes/data/repositories/interfaces/quote_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_quotes/core/services/update_service.dart';

// External Services
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // GoogleSignIn requires proper Firebase Console setup:
  // 1. Add SHA-1 & SHA-256 fingerprints to Firebase Console
  // 2. Enable Google Sign-In in Authentication providers
  // 3. OAuth client will be auto-generated in google-services.json
  return GoogleSignIn(
    serverClientId:
        '958725673026-q173iglhhef0av7tbo402uttr61sc7d2.apps.googleusercontent.com',
  );
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

final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSourceImpl(firestore: ref.watch(firestoreProvider));
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authDataSource: ref.watch(authRemoteDataSourceProvider),
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepositoryImpl(
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
  );
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});
