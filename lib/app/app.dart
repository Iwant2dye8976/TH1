import 'package:flutter/material.dart';

import '../features/documents/presentation/controllers/document_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.controller});

  final DocumentController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter(controller).onGenerateRoute,
    );
  }
}
