import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class UserErrorMessage {
  static String from(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'operation-not-allowed' =>
          'Đăng nhập Google chưa được bật trong cấu hình Firebase.',
        'account-exists-with-different-credential' =>
          'Email này đã được đăng ký bằng một phương thức đăng nhập khác.',
        _ => 'Đăng nhập thất bại. Vui lòng thử lại.',
      };
    }

    if (error is PostgrestException) {
      if (error.code == '42501') {
        final message = error.message.toLowerCase();
        if (message.contains('documents')) {
          return 'Supabase từ chối lưu thông tin tài liệu theo RLS của bảng documents. '
              'Tệp vừa tải lên đã được dọn; hãy chạy lại supabase_schema.sql mới nhất.';
        }
        if (message.contains('storage.objects')) {
          return 'Supabase Storage từ chối tệp theo RLS của storage.objects. '
              'Kiểm tra bucket learning-docs và các Storage policies.';
        }
        return 'Bạn không có quyền thực hiện thao tác này (RLS, mã 42501). '
            'Kiểm tra chính sách truy cập Supabase.';
      }
      return switch (error.code) {
        'PGRST301' => 'Supabase không xác minh được phiên đăng nhập. Vui lòng đăng xuất rồi đăng nhập lại.',
        '23505' => 'Dữ liệu này đã tồn tại.',
        _ => 'Không thể lưu dữ liệu lên máy chủ. Vui lòng thử lại.',
      };
    }

    if (error is StateError) {
      final message = error.message.toString();
      if (message.contains('đăng nhập Firebase')) {
        return 'Vui lòng đăng nhập trước khi thực hiện thao tác này.';
      }
      if (message.contains('Supabase chưa được cấu hình')) {
        return 'Ứng dụng chưa được cấu hình kết nối Supabase.';
      }
      return message;
    }

    if (error is ArgumentError) return error.message.toString();

    final message = error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|Error):\s*'), '')
        .trim();
    return message.isEmpty ? 'Đã xảy ra lỗi. Vui lòng thử lại.' : message;
  }
}
