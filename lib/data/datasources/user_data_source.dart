import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_quotes/data/dto/user_dto.dart';

abstract class UserDataSource {
  Future<void> saveUser(UserDto user);
  Future<UserDto?> getUser(String uid);
  Future<void> updateUser(UserDto user);
  Future<bool> getUserPreference(String userId, String key, bool defaultValue);
  Future<void> setUserPreference(String userId, String key, bool value);
  Future<void> updateUserFCMToken(String userId, String token);
  Future<void> saveUserFromJson(Map<String, dynamic> data);
  Future<void> deleteUser(String userId);
}

class UserDataSourceImpl implements UserDataSource {
  final FirebaseFirestore _firestore;

  UserDataSourceImpl(this._firestore);

  @override
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  @override
  Future<void> saveUser(UserDto user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  @override
  Future<UserDto?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserDto.fromFirestore(doc);
    return null;
  }

  @override
  Future<void> updateUser(UserDto user) async {
    await _firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  @override
  Future<bool> getUserPreference(String userId, String key, bool defaultValue) async {
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
  Future<void> saveUserFromJson(Map<String, dynamic> data) async {
    final userId = data['id'] as String;
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }
}
