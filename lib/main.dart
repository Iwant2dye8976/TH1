import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/storage/supabase_file_storage.dart';
import 'features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/documents/data/datasources/document_local_datasource.dart';
import 'features/documents/data/datasources/supabase_document_remote_data_source.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/domain/usecases/create_document.dart';
import 'features/documents/domain/usecases/delete_document.dart';
import 'features/documents/domain/usecases/get_document_permissions.dart';
import 'features/documents/domain/usecases/list_documents.dart';
import 'features/documents/domain/usecases/revoke_document_permission.dart';
import 'features/documents/domain/usecases/search_documents.dart';
import 'features/documents/domain/usecases/share_document.dart';
import 'features/documents/domain/usecases/update_document.dart';
import 'features/documents/presentation/controllers/document_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();

  SupabaseClient? supabaseClient;
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
    supabaseClient = Supabase.instance.client;
  }

  final preferences = await SharedPreferences.getInstance();

  final authDataSource = FirebaseAuthRemoteDataSource(
    FirebaseAuth.instance,
    supabaseClient,
  );
  final authRepository = AuthRepositoryImpl(authDataSource);

  final repository = DocumentRepositoryImpl(
    PreferencesDocumentLocalDataSource(preferences),
    remoteDataSource: SupabaseDocumentRemoteDataSource(supabaseClient),
    authRepository: authRepository,
  );

  final shareDocumentUseCase = ShareDocument(repository);
  final getPermissionsUseCase = GetDocumentPermissions(repository);
  final revokePermissionUseCase = RevokeDocumentPermission(repository);

  final documentController = DocumentController(
    ListDocuments(repository),
    CreateDocument(repository),
    UpdateDocument(repository),
    DeleteDocument(repository),
    SearchDocuments(repository),
    shareDocument: shareDocumentUseCase,
    getDocumentPermissions: getPermissionsUseCase,
    revokeDocumentPermission: revokePermissionUseCase,
    fileStorage: SupabaseFileStorage(
      client: supabaseClient,
      bucketName: AppConfig.supabaseStorageBucket,
    ),
    authRepository: authRepository,
  );

  final authController = AuthController(
    authRepository,
    dataSource: authDataSource,
  );

  await documentController.load();

  runApp(App(controller: documentController, authController: authController));
}
