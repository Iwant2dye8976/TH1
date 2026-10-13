import 'dart:async';
import '../../domain/entities/user_profile.dart';

abstract class AuthRemoteDataSource {
  Stream<UserProfile?> watchCurrentUser();
  UserProfile? get currentUser;
  Future<UserProfile> signInWithGoogle();
  Future<void> signOut();
  Future<void> switchUser(UserProfile user); // Dùng cho testing & demo đa tài khoản
}

/// Triển khai Mock / In-Memory Auth DataSource cho phép kiểm thử và chuyển đổi
/// linh hoạt giữa 3 người dùng (User A - Owner, User B - Editor, User C - Viewer)
class InMemoryAuthRemoteDataSource implements AuthRemoteDataSource {
  InMemoryAuthRemoteDataSource({UserProfile? initialUser}) {
    _currentUser = initialUser;
  }

  static final List<UserProfile> demoUsers = [
    UserProfile(
      id: 'user-a-owner-id',
      email: 'usera.owner@example.com',
      displayName: 'Nguyễn Văn A (Chủ sở hữu)',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=UserA',
      createdAt: DateTime(2026, 1, 1),
    ),
    UserProfile(
      id: 'user-b-editor-id',
      email: 'userb.editor@example.com',
      displayName: 'Trần Thị B (Người chỉnh sửa)',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=UserB',
      createdAt: DateTime(2026, 1, 2),
    ),
    UserProfile(
      id: 'user-c-viewer-id',
      email: 'userc.viewer@example.com',
      displayName: 'Lê Văn C (Người xem)',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=UserC',
      createdAt: DateTime(2026, 1, 3),
    ),
  ];

  UserProfile? _currentUser;
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    // Mặc định đăng nhập User A (Chủ sở hữu) khi bấm Google Sign-In trong chế độ mock
    _currentUser = demoUsers[0];
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> switchUser(UserProfile user) async {
    _currentUser = user;
    _controller.add(_currentUser);
  }

  void dispose() {
    _controller.close();
  }
}

