# AI Agent Architecture Specification

## Hệ thống Quản lý Tài liệu Học tập

> **Mục đích:** Tài liệu này là đặc tả kiến trúc dành cho AI Coding
> Agent. Agent phải sử dụng nó làm nguyên tắc nền tảng khi tạo mới, sửa
> đổi, refactor hoặc mở rộng hệ thống quản lý tài liệu học tập.
>
> **Nguồn cảm hứng kiến trúc:** Cashew (`jameskokoska/Cashew`). Cashew
> là ứng dụng Flutter lớn sử dụng Flutter + Drift/SQL + Firebase, có tổ
> chức theo page/widget, database layer, global/application services và
> synchronization. Repository cũng có quy trình migration database bằng
> Drift. Tuy nhiên, hệ thống mới phải **học các ưu điểm và tránh
> coupling quá mức** của Cashew.
> [Cashew](https://github.com/jameskokoska/Cashew)

------------------------------------------------------------------------

## 1. Mục tiêu hệ thống

Xây dựng một ứng dụng quản lý tài liệu học tập có tính:

-   **Modular:** từng chức năng có ranh giới rõ ràng.
-   **Extensible:** có thể thêm chức năng mới mà ít ảnh hưởng chức năng
    hiện tại.
-   **Maintainable:** dễ đọc, dễ test, dễ refactor.
-   **Local-first:** thao tác CRUD cơ bản hoạt động trên local database.
-   **Searchable:** tìm kiếm nhanh theo tiêu đề, môn học, tác giả, loại
    tài liệu, tag và nội dung đã lập chỉ mục.
-   **File-oriented:** tài liệu có thể tham chiếu đến PDF, DOCX, PPTX,
    ảnh, video hoặc URL.
-   **Ready for sync:** kiến trúc cho phép bổ sung cloud sync/backup mà
    không phải thay đổi UI.
-   **AI-friendly:** AI Agent có thể xác định đúng module trước khi sửa
    code.

### Chức năng cốt lõi

1.  Thêm tài liệu.
2.  Xem danh sách tài liệu.
3.  Xem chi tiết tài liệu.
4.  Sửa tài liệu.
5.  Xóa tài liệu.
6.  Tìm kiếm tài liệu.
7.  Lọc tài liệu.
8.  Phân loại tài liệu.
9.  Gắn tag.
10. Quản lý file/URL liên quan.

Các chức năng nâng cao như đồng bộ cloud, OCR, semantic search, preview,
authentication hoặc AI assistant phải được thiết kế dưới dạng module mở
rộng, không làm rối core CRUD.

------------------------------------------------------------------------

# 2. Nguyên tắc kiến trúc

## 2.1. Feature-first ở cấp nghiệp vụ

Không tổ chức toàn bộ project thành các thư mục khổng lồ như:

``` text
pages/
widgets/
models/
services/
utils/
```

rồi để tất cả nghiệp vụ trộn vào nhau.

Thay vào đó, ưu tiên:

``` text
features/
├── documents/
├── categories/
├── tags/
└── search/
```

Mỗi feature tự quản lý presentation, domain và data của chính nó.

------------------------------------------------------------------------

## 2.2. Layered architecture bên trong từng feature

Mỗi feature có thể chia:

``` text
presentation
domain
data
```

Ví dụ:

``` text
features/documents/
├── presentation/
├── domain/
└── data/
```

Quy tắc dependency:

``` text
Presentation
     ↓
Domain
     ↑
Data
```

Cụ thể:

``` text
UI
 ↓
Controller / State
 ↓
Use Case
 ↓
Repository interface
 ↓
Repository implementation
 ↓
Local Data Source / Remote Data Source
 ↓
Database / File Storage / API
```

**Domain không được phụ thuộc trực tiếp vào Flutter UI, SQLite, Firebase
hoặc HTTP client.**

------------------------------------------------------------------------

## 2.3. Không tạo "God file"

Cashew có các file utility/application rất lớn trong quá trình phát
triển thực tế. Với project mới, tuyệt đối không biến:

``` text
functions.dart
utils.dart
services.dart
database.dart
```

thành nơi chứa mọi logic.

Thay vào đó:

``` text
core/
├── routing/
├── error/
├── logging/
├── storage/
└── utils/

features/documents/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── ...
```

Mỗi file nên có một trách nhiệm rõ ràng.

------------------------------------------------------------------------

# 3. Cây thư mục chuẩn

``` text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── config/
│       └── app_config.dart
│
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   ├── migrations/
│   │   └── database_provider.dart
│   │
│   ├── storage/
│   │   ├── file_storage.dart
│   │   └── local_file_storage.dart
│   │
│   ├── search/
│   │   ├── search_index.dart
│   │   └── search_query.dart
│   │
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── failure.dart
│   │
│   ├── logging/
│   │   └── app_logger.dart
│   │
│   ├── network/
│   │   └── api_client.dart
│   │
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_dialog.dart
│   │   ├── loading_view.dart
│   │   └── empty_state.dart
│   │
│   └── utils/
│       ├── date_utils.dart
│       ├── file_utils.dart
│       └── validation_utils.dart
│
├── features/
│   │
│   ├── documents/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── document_local_datasource.dart
│   │   │   │   └── document_remote_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   └── document_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── document_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── document.dart
│   │   │   ├── repositories/
│   │   │   │   └── document_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_document.dart
│   │   │       ├── update_document.dart
│   │   │       ├── delete_document.dart
│   │   │       ├── get_document.dart
│   │   │       ├── list_documents.dart
│   │   │       └── search_documents.dart
│   │   │
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── document_list_page.dart
│   │       │   ├── document_detail_page.dart
│   │       │   └── document_form_page.dart
│   │       ├── widgets/
│   │       │   ├── document_card.dart
│   │       │   ├── document_search_bar.dart
│   │       │   ├── document_filter.dart
│   │       │   └── document_form.dart
│   │       └── controllers/
│   │           └── document_controller.dart
│   │
│   ├── categories/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── tags/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── search/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/
    ├── constants/
    └── extensions/
```

------------------------------------------------------------------------

# 4. Vai trò của từng tầng

## 4.1. `app/`

Chứa cấu hình cấp ứng dụng:

-   Khởi tạo app.
-   Routing.
-   Theme.
-   Dependency injection.
-   Configuration.

Không đặt business logic tài liệu ở đây.

------------------------------------------------------------------------

## 4.2. `core/`

Chứa hạ tầng dùng chung cho nhiều feature.

Ví dụ:

``` text
core/database/
core/storage/
core/network/
core/widgets/
core/errors/
```

Một module chỉ được đưa vào `core` nếu nó thực sự dùng chung.

Không đưa logic riêng của `documents` vào `core`.

### Ví dụ đúng

``` text
core/storage/file_storage.dart
```

vì nhiều feature có thể lưu file.

### Ví dụ sai

``` text
core/document_price_calculator.dart
```

nếu chỉ Documents sử dụng.

------------------------------------------------------------------------

# 5. Feature `documents`

Đây là feature trung tâm.

## 5.1. Domain

Domain mô tả nghiệp vụ, không biết UI hoặc database cụ thể.

### Entity

``` text
Document
├── id
├── title
├── description
├── documentType
├── subjectId
├── author
├── filePath
├── externalUrl
├── tags
├── createdAt
└── updatedAt
```

### Document type

Có thể mở rộng:

``` text
lecture
assignment
reference
exam
note
other
```

Không hard-code loại tài liệu ở UI.

------------------------------------------------------------------------

# 6. Repository pattern

Domain định nghĩa interface:

``` dart
abstract class DocumentRepository {
  Future<Document> create(Document document);

  Future<Document?> getById(String id);

  Stream<List<Document>> watchAll();

  Future<Document> update(Document document);

  Future<void> delete(String id);

  Future<List<Document>> search(DocumentSearchQuery query);
}
```

Data layer triển khai interface:

``` text
DocumentRepository
       ↑
       │ implements
       │
DocumentRepositoryImpl
       │
       ├── LocalDataSource
       └── RemoteDataSource
```

UI chỉ biết:

``` text
DocumentRepository
```

không biết:

``` text
SQLite
Drift
Firebase
REST API
```

------------------------------------------------------------------------

# 7. Use Case layer

Mỗi hành động nghiệp vụ quan trọng có một use case.

``` text
create_document.dart
update_document.dart
delete_document.dart
get_document.dart
list_documents.dart
search_documents.dart
```

Ví dụ:

``` dart
class CreateDocument {
  final DocumentRepository repository;

  CreateDocument(this.repository);

  Future<Document> call(Document document) {
    return repository.create(document);
  }
}
```

Use case không được:

-   Hiển thị SnackBar.
-   Điều hướng page.
-   Truy cập trực tiếp database.
-   Đọc BuildContext.
-   Biết widget nào đang gọi nó.

------------------------------------------------------------------------

# 8. Presentation layer

Presentation chịu trách nhiệm:

-   Hiển thị dữ liệu.
-   Nhận input.
-   Validation cấp UI.
-   Loading/error/empty state.
-   Gọi controller.
-   Điều hướng.

Presentation không tự viết SQL.

### Ví dụ

``` text
DocumentListPage
       ↓
DocumentController
       ↓
ListDocuments / SearchDocuments
       ↓
DocumentRepository
```

------------------------------------------------------------------------

# 9. Controller / State management

Controller là cầu nối giữa UI và domain.

``` text
UI
 │
 ▼
Controller
 │
 ├── loading
 ├── data
 ├── error
 └── user actions
 │
 ▼
UseCase
```

Controller không truy cập:

``` text
Drift
SQLite
Firebase
FileSystem
```

trực tiếp.

------------------------------------------------------------------------

# 10. Data layer

Data layer chịu trách nhiệm chuyển đổi giữa domain và nguồn dữ liệu.

``` text
Domain Entity
      ↕
Data Model
      ↕
Database Record / API JSON
```

Ví dụ:

``` text
Document
   ↕
DocumentModel
   ↕
DocumentsTable
```

Không để database model lan vào presentation.

------------------------------------------------------------------------

# 11. Database architecture

Có thể sử dụng Drift/SQLite theo tinh thần Cashew.

``` text
core/database/
├── app_database.dart
├── tables/
│   ├── documents_table.dart
│   ├── categories_table.dart
│   ├── tags_table.dart
│   └── document_tags_table.dart
│
└── migrations/
    ├── schema_v1.json
    ├── schema_v2.json
    └── migration_steps.dart
```

Database nên hỗ trợ:

-   Primary key.
-   Foreign key.
-   Index.
-   Full-text search nếu cần.
-   Timestamps.
-   Soft delete nếu nghiệp vụ yêu cầu.

------------------------------------------------------------------------

# 12. Database schema đề xuất

## Documents

``` text
documents
├── id
├── title
├── description
├── type
├── subject_id
├── author
├── file_path
├── external_url
├── mime_type
├── file_size
├── created_at
├── updated_at
└── deleted_at
```

## Categories / Subjects

``` text
categories
├── id
├── name
├── description
└── created_at
```

## Tags

``` text
tags
├── id
├── name
└── created_at
```

## Many-to-many

``` text
document_tags
├── document_id
└── tag_id
```

Quan hệ:

``` text
Category 1 ─────── N Document

Document N ─────── N Tag
```

------------------------------------------------------------------------

# 13. CRUD architecture

## 13.1. Create

``` text
DocumentFormPage
       ↓
DocumentController.create()
       ↓
CreateDocument
       ↓
DocumentRepository.create()
       ↓
DocumentRepositoryImpl
       ↓
DocumentLocalDataSource
       ↓
Drift
       ↓
SQLite
```

Sau khi thành công:

``` text
SQLite
   ↓
watchAll()
   ↓
Controller state
   ↓
UI rebuild
```

Không cần page tự reload thủ công nếu state layer dùng stream/reactive
query.

------------------------------------------------------------------------

# 14. Update

``` text
DocumentDetailPage
       ↓
Edit Document
       ↓
DocumentFormPage
       ↓
DocumentController.update()
       ↓
UpdateDocument
       ↓
Repository
       ↓
LocalDataSource
       ↓
Database
```

Validation:

``` text
UI validation
    +
Domain/business validation
```

UI validation chỉ giúp UX.

Business validation phải nằm ở domain/use case/entity level.

------------------------------------------------------------------------

# 15. Delete

Delete phải đi qua use case:

``` text
UI
 ↓
Controller
 ↓
DeleteDocument
 ↓
Repository
 ↓
DataSource
 ↓
Database
```

Không cho phép:

``` text
Widget → SQL DELETE
```

Nếu dùng soft delete:

``` text
deleted_at = currentTime
```

Thay vì xóa vật lý.

Soft delete hữu ích nếu sau này cần:

-   Undo.
-   Trash.
-   Restore.
-   Audit.
-   Sync conflict resolution.

------------------------------------------------------------------------

# 16. Search architecture

Search phải là một feature độc lập.

``` text
SearchPage
    ↓
SearchController
    ↓
SearchDocuments
    ↓
DocumentRepository.search()
    ↓
SearchDataSource / Database
```

Query object:

``` dart
class DocumentSearchQuery {
  final String? keyword;
  final String? categoryId;
  final String? type;
  final List<String> tagIds;
  final DateTime? from;
  final DateTime? to;
}
```

Không truyền hàng loạt primitive parameters như:

``` text
search(String keyword, String category, String type, ...)
```

Hãy gom thành một query object để dễ mở rộng.

------------------------------------------------------------------------

# 17. Search strategy

Giai đoạn đầu:

``` text
title
description
author
category
tags
```

Có thể dùng database indexes.

Khi dữ liệu lớn:

``` text
SQLite FTS
```

hoặc:

``` text
Remote search engine
```

Khi cần semantic search:

``` text
Document
   ↓
Text extraction
   ↓
Chunking
   ↓
Embedding
   ↓
Vector database
   ↓
Semantic Search
```

Semantic search phải là module bổ sung, không được trộn với CRUD
repository.

------------------------------------------------------------------------

# 18. File storage architecture

Database không nên chứa toàn bộ binary file nếu không cần thiết.

Thay vào đó:

``` text
Database
   │
   ├── metadata
   ├── file_path
   ├── mime_type
   └── file_size
          │
          ▼
     File Storage
```

Ví dụ:

``` text
storage/
├── documents/
│   ├── {documentId}/
│   │   ├── original.pdf
│   │   └── thumbnail.png
```

Domain chỉ biết:

``` text
file reference
```

không biết đường dẫn vật lý cụ thể.

------------------------------------------------------------------------

# 19. Cloud sync architecture

Thiết kế sẵn abstraction:

``` dart
abstract class DocumentRemoteDataSource {
  Future<void> upload(Document document);
  Future<void> update(Document document);
  Future<void> delete(String id);
  Future<List<Document>> fetchChanges();
}
```

Repository:

``` text
DocumentRepositoryImpl
        │
        ├── LocalDataSource
        │
        └── RemoteDataSource
```

Luồng sync:

``` text
Local Database
      │
      ▼
Sync Queue
      │
      ▼
Remote Data Source
      │
      ▼
Cloud
```

UI không biết sync đang dùng Firebase, REST hay một backend khác.

------------------------------------------------------------------------

# 20. Nguyên tắc Local-first

CRUD nên ưu tiên:

``` text
UI
 ↓
Use Case
 ↓
Repository
 ↓
Local DB
 ↓
UI updated immediately
```

Sau đó:

``` text
Local DB
 ↓
Sync Queue
 ↓
Cloud
```

Không bắt UI chờ cloud nếu nghiệp vụ không yêu cầu.

------------------------------------------------------------------------

# 21. Dependency rules

## Được phép

``` text
presentation → domain
data → domain
data → core
presentation → core
domain → core (chỉ abstraction/value types cần thiết)
```

## Không được phép

``` text
domain → presentation
domain → database
domain → firebase
presentation → Drift
presentation → Firebase
presentation → raw SQL
```

Đặc biệt:

``` text
Widget → Database
```

là anti-pattern trong kiến trúc này.

------------------------------------------------------------------------

# 22. Quy tắc import

Một feature có thể import:

``` text
core/*
```

và các abstraction domain cần thiết.

Không import sâu sang implementation của feature khác.

Sai:

``` dart
import '../other_feature/data/repositories/...';
```

Đúng:

``` text
Feature A
    ↓
Shared/domain abstraction
```

Nếu hai feature cần giao tiếp thường xuyên, tạo abstraction rõ ràng thay
vì truy cập private implementation của nhau.

------------------------------------------------------------------------

# 23. Shared widgets

Chỉ đưa widget vào:

``` text
core/widgets/
```

khi widget thực sự generic.

Ví dụ:

``` text
AppButton
AppDialog
AppTextField
LoadingView
EmptyState
ErrorView
```

Không đưa:

``` text
DocumentCard
DocumentForm
DocumentSearchBar
```

vào `core/widgets`.

Các widget này phải ở:

``` text
features/documents/presentation/widgets/
```

------------------------------------------------------------------------

# 24. Navigation

Tất cả route nên được quản lý tại:

``` text
app/router/
```

Ví dụ:

``` text
/documents
/documents/new
/documents/:id
/documents/:id/edit
/search
/categories
```

Feature không tự tạo global navigation helper chứa mọi logic.

Route argument nên truyền ID hoặc typed route data, không truyền
database object lớn nếu không cần.

------------------------------------------------------------------------

# 25. Error handling

Domain/data không được trực tiếp:

``` text
showSnackBar()
showDialog()
```

Thay vào đó:

``` text
Data error
   ↓
Failure / Exception
   ↓
Controller
   ↓
UI
   ↓
Error widget / Snackbar
```

Các loại lỗi có thể gồm:

``` text
ValidationFailure
NotFoundFailure
StorageFailure
DatabaseFailure
NetworkFailure
PermissionFailure
UnknownFailure
```

------------------------------------------------------------------------

# 26. Validation

### Presentation validation

Kiểm tra nhanh:

``` text
title != empty
file extension hợp lệ
URL hợp lệ
```

### Domain validation

Kiểm tra nghiệp vụ:

``` text
Document phải có title
Document phải có ít nhất file hoặc URL
Document type phải hợp lệ
Category phải tồn tại nếu được chỉ định
```

Không chỉ dựa vào validation của form.

------------------------------------------------------------------------

# 27. State flow

Trạng thái chuẩn:

``` text
Initial
  ↓
Loading
  ↓
Success(data)
```

hoặc:

``` text
Loading
  ↓
Error(failure)
```

Đối với danh sách:

``` text
Loading
Empty
Loaded
Error
```

Search:

``` text
Idle
Searching
Results
Empty
Error
```

Không để mỗi page tự định nghĩa state theo cách khác nhau nếu có thể
chuẩn hóa.

------------------------------------------------------------------------

# 28. Khi AI Agent nhận task mới

Agent phải thực hiện theo quy trình:

``` text
1. Xác định feature.
2. Xác định layer.
3. Tìm entity/use case/repository hiện có.
4. Kiểm tra dependency.
5. Tái sử dụng abstraction hiện có.
6. Chỉ tạo file mới nếu thực sự cần.
7. Không đưa logic vào global utility.
8. Không bypass repository/use case.
9. Cập nhật test.
10. Kiểm tra toàn bộ dependency sau thay đổi.
```

------------------------------------------------------------------------

# 29. Ví dụ task: "Thêm chức năng xóa tài liệu"

Agent phải tìm:

``` text
features/documents/domain/usecases/delete_document.dart
features/documents/domain/repositories/document_repository.dart
features/documents/data/repositories/document_repository_impl.dart
features/documents/data/datasources/document_local_datasource.dart
features/documents/presentation/controllers/document_controller.dart
```

Nếu đã tồn tại, sửa các abstraction cần thiết thay vì tạo:

``` text
delete_document_service.dart
delete_document_helper.dart
delete_document_function.dart
```

Không tạo thêm global function chỉ để thực hiện một use case.

------------------------------------------------------------------------

# 30. Ví dụ task: "Thêm semantic search"

Không sửa CRUD thành:

``` text
DocumentRepository.search()
```

với hàng trăm if/else.

Tạo abstraction:

``` text
SearchProvider
├── KeywordSearchProvider
└── SemanticSearchProvider
```

Có thể mở rộng:

``` text
SearchService
   │
   ├── KeywordSearch
   ├── FullTextSearch
   └── SemanticSearch
```

Search UI vẫn chỉ gọi:

``` text
SearchDocuments
```

------------------------------------------------------------------------

# 31. Ví dụ task: "Thêm OCR PDF"

Không sửa `DocumentRepository` để chứa toàn bộ OCR pipeline.

Tạo:

``` text
features/document_processing/
├── domain/
│   ├── extract_text.dart
│   └── process_document.dart
│
├── data/
│   ├── pdf_text_extractor.dart
│   └── ocr_service.dart
│
└── presentation/
```

Luồng:

``` text
Document
   ↓
DocumentProcessor
   ↓
Text Extraction
   ↓
ExtractedText
   ↓
Search Index
```

CRUD Documents vẫn hoạt động độc lập.

------------------------------------------------------------------------

# 32. Test architecture

Mỗi layer phải có test tương ứng.

``` text
test/
├── features/
│   └── documents/
│       ├── domain/
│       │   └── usecases/
│       ├── data/
│       │   ├── repositories/
│       │   └── datasources/
│       └── presentation/
│           └── controllers/
│
└── core/
```

Ưu tiên:

``` text
Domain tests
   >
Repository tests
   >
Controller tests
   >
Widget tests
   >
Integration tests
```

Không yêu cầu widget test cho mọi business rule.

------------------------------------------------------------------------

# 33. Database migration

Khi thay đổi schema:

``` text
1. Update table definition.
2. Increment schema version.
3. Generate database code.
4. Create migration.
5. Test migration from previous version.
6. Test fresh installation.
7. Test existing data preservation.
```

Không xóa database để "fix" migration trong production.

Mỗi migration phải có backward-data consideration.

------------------------------------------------------------------------

# 34. Quy tắc mở rộng module

Một feature mới nên có dạng:

``` text
features/<feature_name>/
├── data/
├── domain/
└── presentation/
```

Ví dụ thêm `study_sessions`:

``` text
features/study_sessions/
├── data/
├── domain/
└── presentation/
```

Không sửa hàng loạt:

``` text
global_functions.dart
global_models.dart
global_services.dart
```

chỉ để thêm feature.

------------------------------------------------------------------------

# 35. Module boundaries

### Documents

Chịu trách nhiệm:

-   CRUD tài liệu.
-   Metadata.
-   Document detail.
-   Document list.

### Categories

Chịu trách nhiệm:

-   CRUD category/subject.
-   Category selection.

### Tags

Chịu trách nhiệm:

-   Tag management.
-   Tag assignment.

### Search

Chịu trách nhiệm:

-   Query.
-   Filtering.
-   Indexing abstraction.
-   Search ranking.

### Document Processing

Chịu trách nhiệm:

-   PDF extraction.
-   OCR.
-   Thumbnail.
-   Metadata extraction.

### Sync

Chịu trách nhiệm:

-   Upload.
-   Download.
-   Conflict resolution.
-   Sync queue.

Không module nào được ôm trách nhiệm của module khác.

------------------------------------------------------------------------

# 36. Data flow chuẩn

``` text
                    ┌─────────────────────┐
                    │     Presentation    │
                    │ Page / Widget       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Controller / State  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      Use Case       │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Repository Interface│
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
             Local Data Source      Remote Data Source
                    │                     │
                    ▼                     ▼
                 SQLite                Cloud/API
                    │                     │
                    └──────────┬──────────┘
                               ▼
                         Domain Entity
                               │
                               ▼
                              UI
```

------------------------------------------------------------------------

# 37. CRUD sequence tổng quát

## Create

``` text
Form
 ↓
Controller
 ↓
CreateDocument
 ↓
Repository
 ↓
LocalDataSource
 ↓
Database
 ↓
State update
 ↓
UI
```

## Read

``` text
Page
 ↓
Controller
 ↓
Get/ListDocuments
 ↓
Repository
 ↓
Database
 ↓
Entity
 ↓
UI
```

## Update

``` text
Form
 ↓
Controller
 ↓
UpdateDocument
 ↓
Repository
 ↓
Database
 ↓
State update
 ↓
UI
```

## Delete

``` text
Confirmation
 ↓
Controller
 ↓
DeleteDocument
 ↓
Repository
 ↓
Database
 ↓
State update
 ↓
UI
```

## Search

``` text
SearchBar
 ↓
SearchController
 ↓
SearchDocuments
 ↓
SearchQuery
 ↓
Repository
 ↓
SearchDataSource
 ↓
Results
 ↓
UI
```

------------------------------------------------------------------------

# 38. Quy tắc cho AI Agent

AI Agent **MUST**:

-   Giữ feature isolation.
-   Tôn trọng dependency direction.
-   Tái sử dụng repository/use case hiện có.
-   Tạo abstraction trước khi thêm infrastructure mới.
-   Đặt shared code vào `core` chỉ khi thực sự generic.
-   Giữ database access trong data layer.
-   Viết test cho business logic mới.
-   Giữ migration an toàn.
-   Không phá public interfaces nếu không cần thiết.
-   Ưu tiên thay đổi nhỏ, có thể review.

AI Agent **MUST NOT**:

-   Viết SQL trong Widget.
-   Gọi Firebase trực tiếp từ UI.
-   Import database implementation vào domain.
-   Tạo global singleton cho mọi thứ.
-   Tạo file `functions.dart` chứa logic không liên quan.
-   Đưa toàn bộ model vào một file khổng lồ.
-   Copy-paste business logic giữa các feature.
-   Bỏ qua repository để "làm nhanh".
-   Xóa database để xử lý migration.
-   Thêm dependency chỉ khi một abstraction đơn giản đã đủ.

------------------------------------------------------------------------

# 39. Decision rules cho Agent

Khi không biết code nên nằm đâu:

``` text
Có phải UI không?
    → presentation

Có phải nghiệp vụ không?
    → domain

Có phải truy cập DB/API/file system không?
    → data

Có phải infrastructure dùng chung không?
    → core

Có phải chỉ dành cho một feature?
    → feature đó

Có phải dùng bởi nhiều feature?
    → cân nhắc core/shared

Có phải cloud provider-specific?
    → data/infrastructure

Có phải route/theme/app configuration?
    → app
```

------------------------------------------------------------------------

# 40. Mục tiêu kiến trúc

Hệ thống cuối cùng phải đạt:

``` text
                         Application
                              │
             ┌────────────────┼────────────────┐
             │                │                │
         Documents         Search          Processing
             │                │                │
             └────────────────┼────────────────┘
                              │
                         Shared Domain
                              │
                         Data Abstraction
                              │
              ┌───────────────┼───────────────┐
              │               │               │
            SQLite         File Storage      Cloud
```

Mục tiêu không phải là tạo thật nhiều layer.

Mục tiêu là:

> **Mỗi phần của hệ thống có một trách nhiệm rõ ràng, dependency có
> hướng, feature có thể mở rộng độc lập và infrastructure có thể thay
> thế mà không làm thay đổi UI/domain.**

------------------------------------------------------------------------

# 41. Kiến trúc tham chiếu cuối cùng

``` text
lib/
│
├── app/
│
├── core/
│   ├── database/
│   ├── storage/
│   ├── search/
│   ├── network/
│   ├── errors/
│   ├── logging/
│   └── widgets/
│
├── features/
│   ├── documents/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── categories/
│   ├── tags/
│   ├── search/
│   ├── document_processing/
│   └── sync/
│
└── shared/
```

### Dependency

``` text
Presentation
      ↓
    Domain
      ↑
     Data
      ↓
Infrastructure
```

### Core principle

``` text
UI không biết Database.

Domain không biết Flutter.

Domain không biết Firebase.

Data không quyết định UI.

Feature không phụ thuộc implementation của feature khác.

Infrastructure có thể thay thế.

CRUD là module độc lập.

Search là module có thể nâng cấp từ keyword → FTS → semantic search.

File processing có thể bổ sung OCR/thumbnail/text extraction mà không phá Documents CRUD.
```

------------------------------------------------------------------------

# 42. Acceptance criteria cho AI Agent

Một implementation được xem là đạt kiến trúc khi:

-   [ ] Có `features/documents`.
-   [ ] Documents có `presentation`, `domain`, `data`.
-   [ ] CRUD đi qua use case/repository.
-   [ ] UI không truy cập database trực tiếp.
-   [ ] Domain không import Flutter/Drift/Firebase.
-   [ ] Database schema nằm trong data/core database.
-   [ ] Search dùng query object.
-   [ ] File storage tách khỏi database metadata.
-   [ ] Có thể thay local storage bằng remote storage mà không sửa UI.
-   [ ] Có migration strategy.
-   [ ] Có unit tests cho use cases/repository.
-   [ ] Không có global `functions.dart` chứa business logic.
-   [ ] Shared widgets không chứa logic nghiệp vụ.
-   [ ] Feature mới có thể thêm mà không cần sửa một "god module".
-   [ ] Error được truyền qua abstraction thay vì hiển thị trực tiếp từ
    data layer.
-   [ ] Agent có thể trace một request từ UI → Controller → Use Case →
    Repository → Data Source.

------------------------------------------------------------------------

## 43. Tham chiếu Cashew

Kiến trúc này kế thừa có chọn lọc các ý tưởng từ Cashew:

  Ý tưởng từ Cashew              Cách áp dụng
  ------------------------------ -----------------------------------------
  Page-oriented UI               `presentation/pages`
  Reusable widgets               `presentation/widgets` + `core/widgets`
  Database-first/local storage   Drift/SQLite
  Generated database code        Code generation
  Schema migration               Versioned migrations
  Application services           Tách thành các service/use case nhỏ
  Sync client                    Module `sync` độc lập
  Firebase integration           Remote data source
  Search/filter                  `SearchQuery` + Search feature
  Multi-platform                 Giữ infrastructure độc lập UI

Không sao chép nguyên trạng các điểm có thể tạo coupling như global
utility quá lớn hoặc dependency chéo giữa UI và database.

------------------------------------------------------------------------

## 44. Instruction cuối cho AI Agent

Khi thực hiện bất kỳ thay đổi nào trong project:

> **Read architecture first → locate feature → locate layer → reuse
> abstraction → implement smallest coherent change → update tests →
> verify dependency direction → verify migration if schema changes.**

Nếu một yêu cầu mới không phù hợp với kiến trúc hiện tại, **không phá
kiến trúc để đáp ứng nhanh**. Hãy tạo abstraction/module mới ở đúng
boundary.

Ưu tiên:

``` text
Modularity
>
Clear boundaries
>
Testability
>
Extensibility
>
Convenience
```

Mọi quyết định kiến trúc phải hướng tới việc hệ thống có thể tiếp tục mở
rộng từ một ứng dụng CRUD tài liệu thành một nền tảng quản lý tri thức
học tập mà không phải tái cấu trúc toàn bộ codebase.
