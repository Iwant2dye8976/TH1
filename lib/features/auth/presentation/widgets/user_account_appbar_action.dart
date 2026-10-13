import 'package:flutter/material.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../controllers/auth_controller.dart';
import '../../../documents/presentation/controllers/document_controller.dart';

class UserAccountAppBarAction extends StatelessWidget {
  const UserAccountAppBarAction({
    super.key,
    required this.authController,
    required this.documentController,
  });

  final AuthController authController;
  final DocumentController documentController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authController,
      builder: (context, _) {
        final user = authController.currentUser;
        if (user == null) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: authController.isLoading
                  ? null
                  : () async {
                      await authController.signInWithGoogle();
                      if (!context.mounted) return;
                      final error = authController.errorMessage;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(UserErrorMessage.from(error)),
                          ),
                        );
                      } else {
                        await documentController.load();
                      }
                    },
              icon: authController.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Google Sign-In'),
            ),
          );
        }

        final canSwitchUsers =
            authController.dataSource is InMemoryAuthRemoteDataSource;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            tooltip: 'Tài khoản người dùng',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (canSwitchUsers) ...[
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'CHUYỂN ĐỔI TEST PHÂN QUYỀN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...InMemoryAuthRemoteDataSource.demoUsers.map((u) {
                  final isSelected = u.id == user.id;
                  return PopupMenuItem<String>(
                    value: u.id,
                    onTap: () async {
                      await authController.switchUser(u);
                      await documentController.load();
                    },
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          size: 18,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            u.displayName,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                onTap: () async {
                  await authController.signOut();
                  if (!context.mounted) return;
                  final error = authController.errorMessage;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(UserErrorMessage.from(error)),
                      ),
                    );
                  } else {
                    await documentController.load();
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
