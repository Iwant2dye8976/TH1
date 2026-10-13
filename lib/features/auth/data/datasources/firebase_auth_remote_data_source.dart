import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../domain/entities/user_profile.dart';
import 'auth_remote_datasource.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._firebaseAuth, this._supabaseClient);

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final SupabaseClient? _supabaseClient;

  @override
  UserProfile? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _toProfile(user);
  }

  @override
  Stream<UserProfile?> watchCurrentUser() {
    return _firebaseAuth.userChanges().map(
      (user) => user == null ? null : _toProfile(user),
    );
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    final supabase = _requireSupabase();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google không trả về ID token. Hãy kiểm tra cấu hình OAuth của Firebase.',
      );
    }

    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Firebase không trả về tài khoản sau khi đăng nhập.');
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      await _firebaseAuth.signOut();
      throw StateError('Tài khoản Google không có địa chỉ email.');
    }

    final profile = _toProfile(user);
    try {
      await supabase.from('profiles').upsert({
        'auth_uid': profile.id,
        'email': email,
        'display_name': profile.displayName,
        'photo_url': profile.photoUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_uid');
    } catch (error, stackTrace) {
      await _firebaseAuth.signOut();
      Error.throwWithStackTrace(error, stackTrace);
    }

    return profile.copyWith(email: email);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> switchUser(UserProfile user) {
    throw UnsupportedError(
      'Không thể chuyển tài khoản Firebase sang tài khoản giả lập.',
    );
  }

  SupabaseClient _requireSupabase() {
    final client = _supabaseClient;
    if (client == null) {
      throw StateError(
        'Supabase chưa được cấu hình. Hãy chạy ứng dụng với '
        '--dart-define=SUPABASE_ANON_KEY=<anon-key>.',
      );
    }
    return client;
  }

  static UserProfile _toProfile(firebase_auth.User user) {
    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }
}
