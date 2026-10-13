import '../entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> watchCurrentUser();
  UserProfile? get currentUser;
  Future<UserProfile> signInWithGoogle();
  Future<void> signOut();
}

