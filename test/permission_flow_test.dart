import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:learning_docs/core/search/search_query.dart';
import 'package:learning_docs/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:learning_docs/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:learning_docs/features/auth/domain/entities/user_profile.dart';
import 'package:learning_docs/features/documents/data/datasources/document_local_datasource.dart';
import 'package:learning_docs/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:learning_docs/features/documents/data/repositories/document_repository_impl.dart';
import 'package:learning_docs/features/documents/domain/entities/document_permission.dart';
import 'package:learning_docs/features/documents/domain/usecases/create_document.dart';
import 'package:learning_docs/features/documents/domain/usecases/delete_document.dart';
import 'package:learning_docs/features/documents/domain/usecases/get_document_permissions.dart';
import 'package:learning_docs/features/documents/domain/usecases/list_documents.dart';
import 'package:learning_docs/features/documents/domain/usecases/revoke_document_permission.dart';
import 'package:learning_docs/features/documents/domain/usecases/search_documents.dart';
import 'package:learning_docs/features/documents/domain/usecases/share_document.dart';
import 'package:learning_docs/features/documents/domain/usecases/update_document.dart';
import 'package:learning_docs/features/documents/presentation/controllers/document_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo 3 tài khoản người dùng theo yêu cầu kiểm thử
  final userA = UserProfile(
    id: 'user-a-id',
    email: 'usera.owner@example.com',
    displayName: 'Nguyễn Văn A (Chủ sở hữu)',
  );

  final userB = UserProfile(
    id: 'user-b-id',
    email: 'userb.editor@example.com',
    displayName: 'Trần Thị B (Người chỉnh sửa)',
  );

  final userC = UserProfile(
    id: 'user-c-id',
    email: 'userc.viewer@example.com',
    displayName: 'Lê Văn C (Người xem)',
  );

  final userD = UserProfile(
    id: 'user-d-id',
    email: 'userd.stranger@example.com',
    displayName: 'Người ngoài (Không được chia sẻ)',
  );

  late InMemoryAuthRemoteDataSource authDataSource;
  late AuthRepositoryImpl authRepository;
  late InMemorySupabaseDocumentRemoteDataSource remoteDataSource;
  late DocumentRepositoryImpl repository;
  late DocumentController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    authDataSource = InMemoryAuthRemoteDataSource(initialUser: userA);
    authRepository = AuthRepositoryImpl(authDataSource);
    remoteDataSource = InMemorySupabaseDocumentRemoteDataSource();

    repository = DocumentRepositoryImpl(
      PreferencesDocumentLocalDataSource(preferences),
      remoteDataSource: remoteDataSource,
      authRepository: authRepository,
    );

    controller = DocumentController(
      ListDocuments(repository),
      CreateDocument(repository),
      UpdateDocument(repository),
      DeleteDocument(repository),
      SearchDocuments(repository),
      shareDocument: ShareDocument(repository),
      getDocumentPermissions: GetDocumentPermissions(repository),
      revokeDocumentPermission: RevokeDocumentPermission(repository),
    );
  });

  tearDown(() {
    controller.dispose();
    authDataSource.dispose();
  });

  group('Kiểm thử luồng phân quyền và RLS với ít nhất 3 người dùng khác nhau', () {
    test(
      'KỊCH BẢN: User A tạo tài liệu, chia sẻ cho User B (Editor) và User C (Viewer)',
      () async {
        // ====================================================================
        // BƯỚC 1: USER A (OWNER) TẠO TÀI LIỆU VÀ CHIA SẺ
        // ====================================================================
        await authDataSource.switchUser(userA);
        await controller.create(
          title: 'Tài liệu Giải tích của User A',
          type: 'lecture',
          description: 'Bản thảo bài giảng môn Giải tích 1',
          subject: 'Toán học',
          author: 'Nguyễn Văn A',
          tags: ['toan', 'giai-tich'],
        );

        expect(controller.documents, hasLength(1));
        final createdDoc = controller.documents.first;
        expect(createdDoc.title, 'Tài liệu Giải tích của User A');
        expect(createdDoc.isOwner, isTrue);
        expect(createdDoc.canEdit, isTrue);
        expect(createdDoc.canDelete, isTrue);
        expect(createdDoc.canShare, isTrue);

        // User A chia sẻ cho User B quyền Editor
        await controller.share(
          documentId: createdDoc.id,
          targetEmail: userB.email,
          role: PermissionRole.editor,
        );

        // User A chia sẻ cho User C quyền Viewer
        await controller.share(
          documentId: createdDoc.id,
          targetEmail: userC.email,
          role: PermissionRole.viewer,
        );

        // User A kiểm tra danh sách quyền
        final perms = await controller.fetchPermissions(createdDoc.id);
        expect(perms, hasLength(2));
        expect(perms.any((p) => p.userEmail == userB.email && p.role == PermissionRole.editor), isTrue);
        expect(perms.any((p) => p.userEmail == userC.email && p.role == PermissionRole.viewer), isTrue);

        // ====================================================================
        // BƯỚC 2: USER B (EDITOR) TRUY CẬP VÀ CẬP NHẬT TÀI LIỆU
        // ====================================================================
        await authDataSource.switchUser(userB);
        await controller.load();

        // User B phải thấy tài liệu được chia sẻ
        expect(controller.documents, hasLength(1));
        final docSeenByB = controller.documents.first;
        expect(docSeenByB.id, createdDoc.id);
        expect(docSeenByB.currentUserRole, PermissionRole.editor);
        expect(docSeenByB.isOwner, isFalse);
        expect(docSeenByB.canEdit, isTrue, reason: 'Editor phải có quyền sửa');
        expect(docSeenByB.canDelete, isFalse, reason: 'Editor không có quyền xóa');
        expect(docSeenByB.canShare, isFalse, reason: 'Editor không có quyền chia sẻ');

        // User B tìm kiếm tài liệu theo từ khóa
        await controller.search(DocumentSearchQuery(keyword: 'Giải tích'));
        expect(controller.searchResults, hasLength(1));

        // User B CẬP NHẬT tài liệu -> Phải thành công
        await controller.update(
          original: docSeenByB,
          title: 'Tài liệu Giải tích của User A (Đã được B hiệu đính)',
          type: docSeenByB.type,
          description: 'Bổ sung thêm bài tập ôn thi',
        );

        expect(
          controller.documents.first.title,
          'Tài liệu Giải tích của User A (Đã được B hiệu đính)',
        );

        // User B cố gắng XÓA tài liệu -> Phải bị từ chối bởi chính sách RLS
        expect(
          () => controller.delete(createdDoc.id),
          throwsA(isA<Exception>()),
          reason: 'RLS policy cấm Editor xóa tài liệu của Owner',
        );

        // User B cố gắng CHIA SẺ cho người khác -> Phải bị từ chối bởi RLS
        expect(
          () => controller.share(
            documentId: createdDoc.id,
            targetEmail: 'another@example.com',
            role: PermissionRole.viewer,
          ),
          throwsA(isA<Exception>()),
          reason: 'RLS policy cấm Editor cấp quyền chia sẻ tài liệu',
        );

        // ====================================================================
        // BƯỚC 3: USER C (VIEWER) TRUY CẬP TÀI LIỆU (CHỈ XEM)
        // ====================================================================
        await authDataSource.switchUser(userC);
        await controller.load();

        // User C phải thấy tài liệu đã được B cập nhật
        expect(controller.documents, hasLength(1));
        final docSeenByC = controller.documents.first;
        expect(docSeenByC.currentUserRole, PermissionRole.viewer);
        expect(docSeenByC.canEdit, isFalse, reason: 'Viewer không được sửa');
        expect(docSeenByC.canDelete, isFalse, reason: 'Viewer không được xóa');
        expect(docSeenByC.canShare, isFalse, reason: 'Viewer không được chia sẻ');

        // User C cố gắng CẬP NHẬT tài liệu -> Phải bị từ chối bởi RLS
        expect(
          () => controller.update(
            original: docSeenByC,
            title: 'User C cố tình sửa tiêu đề trái phép',
            type: docSeenByC.type,
          ),
          throwsA(isA<Exception>()),
          reason: 'RLS policy cấm Viewer cập nhật tài liệu',
        );

        // User C cố gắng XÓA tài liệu -> Phải bị từ chối bởi RLS
        expect(
          () => controller.delete(createdDoc.id),
          throwsA(isA<Exception>()),
          reason: 'RLS policy cấm Viewer xóa tài liệu',
        );

        // ====================================================================
        // BƯỚC 4: USER D (NGƯỜI NGOÀI) KHÔNG THỂ THẤY TÀI LIỆU
        // ====================================================================
        await authDataSource.switchUser(userD);
        await controller.load();

        // User D không được chia sẻ bất cứ quyền gì -> Danh sách phải trống
        expect(controller.documents, isEmpty);

        final directGet = await repository.getById(createdDoc.id);
        expect(directGet, isNull, reason: 'RLS chặn User D truy cập trực tiếp bằng ID');

        // ====================================================================
        // BƯỚC 5: USER A (OWNER) THU HỒI QUYỀN VÀ XÓA TÀI LIỆU
        // ====================================================================
        await authDataSource.switchUser(userA);
        await controller.load();

        // User A xóa tài liệu -> Thành công
        await controller.delete(createdDoc.id);
        expect(controller.documents, isEmpty);

        // Sau khi User A xóa, User B vào lại cũng không còn thấy tài liệu nữa
        await authDataSource.switchUser(userB);
        await controller.load();
        expect(controller.documents, isEmpty);
      },
    );
  });
}
