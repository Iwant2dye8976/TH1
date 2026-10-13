import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository, {this.dataSource}) {
    _subscription = _authRepository.watchCurrentUser().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthRepository _authRepository;
  final AuthRemoteDataSource? dataSource;
  StreamSubscription<UserProfile?>? _subscription;

  UserProfile? _currentUser;
  bool _isLoading = false;
  Object? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  Object? get errorMessage => _errorMessage;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authRepository.signInWithGoogle();
    } catch (e) {
      _errorMessage = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cho phép đổi nhanh người dùng (User A, User B, User C) để test phân quyền trực tiếp trên UI
  Future<void> switchUser(UserProfile user) async {
    if (dataSource != null) {
      await dataSource!.switchUser(user);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
