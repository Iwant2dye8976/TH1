import 'package:flutter/material.dart';

import '../../features/documents/presentation/controllers/document_controller.dart';
import '../../features/documents/presentation/pages/document_detail_page.dart';
import '../../features/documents/presentation/pages/document_form_page.dart';
import '../../features/documents/presentation/pages/document_list_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const createDocument = '/documents/new';
  static const search = '/search';

  static String document(String id) => '/documents/${Uri.encodeComponent(id)}';

  static String editDocument(String id) => '${document(id)}/edit';
}

class AppRouter {
  AppRouter(this.controller);

  final DocumentController controller;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.home;
    if (name == AppRoutes.home) {
      return _page(DocumentListPage(controller: controller));
    }
    if (name == AppRoutes.createDocument) {
      return _page(DocumentFormPage(controller: controller));
    }
    if (name == AppRoutes.search) {
      return _page(SearchPage(controller: controller));
    }

    final segments = Uri.parse(name).pathSegments;
    if (segments.length >= 2 && segments.first == 'documents') {
      final id = segments[1];
      final document = controller.documentById(id);
      if (document != null && segments.length == 2) {
        return _page(
          DocumentDetailPage(controller: controller, document: document),
        );
      }
      if (document != null && segments.length == 3 && segments[2] == 'edit') {
        return _page(
          DocumentFormPage(controller: controller, document: document),
        );
      }
    }
    return _page(
      Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy trang')),
        body: const Center(child: Text('Nội dung này không còn tồn tại.')),
      ),
    );
  }

  MaterialPageRoute<void> _page(Widget page) =>
      MaterialPageRoute<void>(builder: (_) => page);
}