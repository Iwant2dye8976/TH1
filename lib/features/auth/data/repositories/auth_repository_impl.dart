import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  UserProfile? get currentUser => _remoteDataSource.currentUser;

  @override
  Stream<UserProfile?> watchCurrentUser() {
    return _remoteDataSource.watchCurrentUser();
  }

  @override
  Future<UserProfile> signInWithGoogle() {
    return _remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}

