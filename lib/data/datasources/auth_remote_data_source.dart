import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> login(String email, String password);
  Future<UserCredential> signup(String email, String password);
  Future<void> logout();
  User? get currentUser;
  Future<UserCredential> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> confirmPasswordReset(String code, String newPassword);
  Future<void> deleteAccount();
  Stream<User?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Future<UserCredential> login(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signup(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    // Obtain the auth details from the request
    final authDetails = googleUser.authentication;
    
    // Authorization (Permissions) - Request scopes to retrieve the Access Token
    final clientAuth = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: clientAuth.accessToken,
      idToken: authDetails.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> resetPassword(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) {
    return _firebaseAuth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
