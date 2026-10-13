-- ============================================================================
-- SUPABASE DATABASE SCHEMA CHO ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP
-- Bao gồm: Bảng Người dùng, Tài liệu, Quyền chia sẻ và Row Level Security (RLS)
-- ============================================================================

-- Bật extension uuid-ossp (nếu chưa bật)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BẢNG NGƯỜI DÙNG (profiles)
-- Đồng bộ hoặc lưu thông tin người dùng từ Auth (Firebase Auth / Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_uid TEXT UNIQUE NOT NULL, -- UID từ Firebase hoặc Supabase Auth
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index tăng tốc tìm kiếm người dùng theo email khi chia sẻ tài liệu
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_uid ON public.profiles(auth_uid);

-- 2. BẢNG TÀI LIỆU (documents)
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id TEXT NOT NULL, -- auth_uid của người tạo (Owner)
    owner_email TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL DEFAULT 'other', -- lecture, assignment, reference, exam, note, other
    subject_id TEXT,
    author TEXT,
    file_path TEXT, -- Tên file hoặc đường dẫn tương đối
    storage_path TEXT, -- Đường dẫn trong private Supabase Storage bucket
    external_url TEXT, -- URL liên kết ngoài nếu không có file
    file_size BIGINT, -- Dung lượng file (bytes)
    mime_type TEXT,
    tags JSONB DEFAULT '[]'::jsonb, -- Danh sách tags dạng JSON mảng
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    deleted_at TIMESTAMPTZ -- Hỗ trợ Soft Delete
);

-- Also updates databases where the table already existed before this default
-- was added; CREATE TABLE IF NOT EXISTS does not modify existing columns.
ALTER TABLE public.documents
    ALTER COLUMN owner_id SET DEFAULT (auth.jwt() ->> 'sub');

-- Indexes tối ưu hóa truy vấn và tìm kiếm tài liệu
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON public.documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_subject ON public.documents(subject_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON public.documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_title_search ON public.documents USING gin(to_tsvector('simple', title));

-- 3. BẢNG PHÂN QUYỀN CHIA SẺ (document_permissions)
-- Quản lý quyền truy cập của người dùng đối với từng tài liệu
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id TEXT, -- auth_uid của người được chia sẻ
    user_email TEXT NOT NULL, -- Email người được chia sẻ (hữu ích khi người dùng chưa đăng ký)
    role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(document_id, user_email)
);

CREATE INDEX IF NOT EXISTS idx_permissions_doc ON public.document_permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_permissions_email ON public.document_permissions(user_email);
CREATE INDEX IF NOT EXISTS idx_permissions_uid ON public.document_permissions(user_id);


-- ============================================================================
-- 4. THIẾT LẬP CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Bật RLS trên tất cả các bảng
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Hàm phụ trợ lấy email của người dùng hiện tại đang request
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_email()
RETURNS TEXT AS $$
BEGIN
    RETURN coalesce(
        current_setting('request.jwt.claims', true)::jsonb ->> 'email',
        (SELECT email FROM public.profiles WHERE auth_uid = auth.jwt() ->> 'sub' LIMIT 1)
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.is_learning_docs_firebase_jwt()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT coalesce(
        auth.jwt() ->> 'iss' = 'https://securetoken.google.com/learning-docs-6ceb8'
        AND auth.jwt() ->> 'aud' = 'learning-docs-6ceb8',
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.document_insert_diagnostics(target_owner_id TEXT)
RETURNS TABLE (
    request_role TEXT,
    firebase_issuer_matches BOOLEAN,
    firebase_audience_matches BOOLEAN,
    firebase_subject_present BOOLEAN,
    owner_matches_firebase_subject BOOLEAN,
    can_insert_documents BOOLEAN,
    can_select_documents BOOLEAN
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT
        auth.role(),
        auth.jwt() ->> 'iss' = 'https://securetoken.google.com/learning-docs-6ceb8',
        auth.jwt() ->> 'aud' = 'learning-docs-6ceb8',
        nullif(auth.jwt() ->> 'sub', '') IS NOT NULL,
        target_owner_id = auth.jwt() ->> 'sub',
        has_table_privilege(auth.role(), 'public.documents', 'INSERT'),
        has_table_privilege(auth.role(), 'public.documents', 'SELECT');
$$;

CREATE OR REPLACE FUNCTION public.has_document_role(
    target_document_id UUID,
    allowed_roles TEXT[]
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.documents d
        WHERE d.id = target_document_id
          AND (
              (d.owner_id = auth.jwt() ->> 'sub' AND 'owner' = ANY(allowed_roles))
              OR EXISTS (
                  SELECT 1
                  FROM public.document_permissions p
                  WHERE p.document_id = d.id
                    AND (
                        p.user_id = auth.jwt() ->> 'sub'
                        OR lower(p.user_email) = lower(public.current_user_email())
                    )
                    AND p.role = ANY(allowed_roles)
              )
          )
    );
$$;

CREATE OR REPLACE FUNCTION public.is_valid_share_recipient(
    target_user_id TEXT,
    target_email TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT target_user_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.auth_uid = target_user_id
          AND lower(p.email) = lower(target_email)
    );
$$;

CREATE OR REPLACE FUNCTION public.find_share_recipient(target_email TEXT)
RETURNS TABLE (
    auth_uid TEXT,
    email TEXT,
    display_name TEXT
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT p.auth_uid, p.email, p.display_name
    FROM public.profiles p
    WHERE public.is_learning_docs_firebase_jwt()
      AND target_email IS NOT NULL
      AND btrim(target_email) <> ''
      AND lower(p.email) = lower(btrim(target_email))
    LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.has_document_role(UUID, TEXT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_document_role(UUID, TEXT[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_learning_docs_firebase_jwt() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.document_insert_diagnostics(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.document_insert_diagnostics(TEXT) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.is_valid_share_recipient(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_valid_share_recipient(TEXT, TEXT) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.find_share_recipient(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.find_share_recipient(TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.prevent_document_owner_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
        RAISE EXCEPTION 'Document ownership cannot be changed'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_document_owner_change ON public.documents;
CREATE TRIGGER prevent_document_owner_change
BEFORE UPDATE OF owner_id ON public.documents
FOR EACH ROW EXECUTE FUNCTION public.prevent_document_owner_change();

CREATE OR REPLACE FUNCTION public.set_document_owner_from_firebase_jwt()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.owner_id := auth.jwt() ->> 'sub';
    IF NEW.owner_id IS NULL OR NEW.owner_id = '' THEN
        RAISE EXCEPTION 'A valid Firebase user is required to create a document'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_document_owner_from_firebase_jwt ON public.documents;
CREATE TRIGGER set_document_owner_from_firebase_jwt
BEFORE INSERT ON public.documents
FOR EACH ROW EXECUTE FUNCTION public.set_document_owner_from_firebase_jwt();

-- Firebase ID tokens without a custom "role" claim are mapped to the anon
-- Postgres role by Supabase. Limit that role to JWTs issued for this Firebase
-- project; a Supabase anon API key by itself must never pass this policy.
GRANT SELECT, INSERT, UPDATE ON public.profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_permissions TO anon, authenticated;

DROP POLICY IF EXISTS "Chỉ nhận JWT từ Firebase Learning Docs" ON public.profiles;
CREATE POLICY "Chỉ nhận JWT từ Firebase Learning Docs"
ON public.profiles AS RESTRICTIVE FOR ALL
TO anon, authenticated
USING (public.is_learning_docs_firebase_jwt())
WITH CHECK (public.is_learning_docs_firebase_jwt());

DROP POLICY IF EXISTS "Chỉ nhận JWT từ Firebase Learning Docs" ON public.documents;
CREATE POLICY "Chỉ nhận JWT từ Firebase Learning Docs"
ON public.documents AS RESTRICTIVE FOR ALL
TO anon, authenticated
USING (public.is_learning_docs_firebase_jwt())
WITH CHECK (public.is_learning_docs_firebase_jwt());

DROP POLICY IF EXISTS "Chỉ nhận JWT từ Firebase Learning Docs" ON public.document_permissions;
CREATE POLICY "Chỉ nhận JWT từ Firebase Learning Docs"
ON public.document_permissions AS RESTRICTIVE FOR ALL
TO anon, authenticated
USING (public.is_learning_docs_firebase_jwt())
WITH CHECK (public.is_learning_docs_firebase_jwt());

-- Private document bucket; signed URLs are generated only after document RLS
-- confirms that the current Firebase user can access the document.
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('learning-docs', 'learning-docs', false, 52428800)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit;

GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon, authenticated;

DROP POLICY IF EXISTS "Chỉ nhận JWT Firebase trên storage" ON storage.objects;
CREATE POLICY "Chỉ nhận JWT Firebase trên storage"
ON storage.objects AS RESTRICTIVE FOR ALL
TO anon, authenticated
USING (public.is_learning_docs_firebase_jwt())
WITH CHECK (public.is_learning_docs_firebase_jwt());

DROP POLICY IF EXISTS "Xem tệp tài liệu được chia sẻ" ON storage.objects;
CREATE POLICY "Xem tệp tài liệu được chia sẻ"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (
    bucket_id = 'learning-docs'
    AND array_length(storage.foldername(name), 1) = 3
    AND storage.foldername(name)[1] = 'documents'
    AND public.has_document_role(
        CASE
            WHEN storage.foldername(name)[3] ~*
                '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN storage.foldername(name)[3]::uuid
        END,
        ARRAY['owner', 'editor', 'viewer']
    )
);

DROP POLICY IF EXISTS "Tải tệp vào thư mục của chính mình" ON storage.objects;
CREATE POLICY "Tải tệp vào thư mục của chính mình"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (
    bucket_id = 'learning-docs'
    AND array_length(storage.foldername(name), 1) = 3
    AND storage.foldername(name)[1] = 'documents'
    AND storage.foldername(name)[2] = auth.jwt() ->> 'sub'
    AND storage.foldername(name)[3] ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
);

DROP POLICY IF EXISTS "Cập nhật tệp của chính mình" ON storage.objects;
CREATE POLICY "Cập nhật tệp của chính mình"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (
    bucket_id = 'learning-docs'
    AND array_length(storage.foldername(name), 1) = 3
    AND storage.foldername(name)[1] = 'documents'
    AND storage.foldername(name)[2] = auth.jwt() ->> 'sub'
    AND storage.foldername(name)[3] ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
)
WITH CHECK (
    bucket_id = 'learning-docs'
    AND array_length(storage.foldername(name), 1) = 3
    AND storage.foldername(name)[1] = 'documents'
    AND storage.foldername(name)[2] = auth.jwt() ->> 'sub'
    AND storage.foldername(name)[3] ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
);

DROP POLICY IF EXISTS "Xóa tệp khi là chủ tài liệu" ON storage.objects;
CREATE POLICY "Xóa tệp khi là chủ tài liệu"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (
    bucket_id = 'learning-docs'
    AND array_length(storage.foldername(name), 1) = 3
    AND storage.foldername(name)[1] = 'documents'
    AND storage.foldername(name)[2] = auth.jwt() ->> 'sub'
);


-- ----------------------------------------------------------------------------
-- POLICIES CHO BẢNG PROFILES
-- ----------------------------------------------------------------------------
-- Profile chỉ được đọc trực tiếp bởi chính chủ; tra cứu người nhận chia sẻ
-- theo email đi qua find_share_recipient và chỉ trả về một kết quả khớp.
DROP POLICY IF EXISTS "Cho phép xem profile người dùng" ON public.profiles;
DROP POLICY IF EXISTS "Người dùng xem profile của chính mình" ON public.profiles;
CREATE POLICY "Người dùng xem profile của chính mình"
ON public.profiles FOR SELECT
TO anon, authenticated
USING (auth_uid = auth.jwt() ->> 'sub');

-- Người dùng chỉ được sửa profile của chính mình
DROP POLICY IF EXISTS "Người dùng tự cập nhật profile" ON public.profiles;
CREATE POLICY "Người dùng tự cập nhật profile"
ON public.profiles FOR UPDATE
TO anon, authenticated
USING (auth_uid = auth.jwt() ->> 'sub')
WITH CHECK (auth_uid = auth.jwt() ->> 'sub');

-- Cho phép thêm profile mới khi đăng nhập lần đầu
DROP POLICY IF EXISTS "Cho phép tạo profile" ON public.profiles;
CREATE POLICY "Cho phép tạo profile"
ON public.profiles FOR INSERT
TO anon, authenticated
WITH CHECK (auth_uid = auth.jwt() ->> 'sub');


-- ----------------------------------------------------------------------------
-- POLICIES CHO BẢNG DOCUMENTS (TÀI LIỆU)
-- ----------------------------------------------------------------------------

-- Quyền 1: XEM TÀI LIỆU (SELECT)
-- Điều kiện: Là Chủ sở hữu (Owner) HOẶC Tài liệu công khai (is_public)
-- HOẶC Được chia sẻ trong bảng document_permissions (với email hoặc user_id tương ứng)
DROP POLICY IF EXISTS "Xem tài liệu hợp lệ" ON public.documents;
CREATE POLICY "Xem tài liệu hợp lệ"
ON public.documents FOR SELECT
TO anon, authenticated
USING (
    deleted_at IS NULL
    AND (
        owner_id = auth.jwt() ->> 'sub'
        OR is_public = true
        OR public.has_document_role(id, ARRAY['editor', 'viewer'])
    )
);

-- Quyền 2: THÊM TÀI LIỆU (INSERT)
-- Điều kiện: Người tạo phải đặt owner_id là UID của chính mình
DROP POLICY IF EXISTS "Thêm tài liệu cho chính mình" ON public.documents;
CREATE POLICY "Thêm tài liệu cho chính mình"
ON public.documents FOR INSERT
TO anon, authenticated
WITH CHECK (
    owner_id = auth.jwt() ->> 'sub'
);

-- Quyền 3: CẬP NHẬT TÀI LIỆU (UPDATE)
-- Điều kiện: Là Chủ sở hữu (Owner) HOẶC có quyền 'editor' trong bảng document_permissions
DROP POLICY IF EXISTS "Chủ sở hữu hoặc Editor được cập nhật tài liệu" ON public.documents;
CREATE POLICY "Chủ sở hữu hoặc Editor được cập nhật tài liệu"
ON public.documents FOR UPDATE
TO anon, authenticated
USING (
    deleted_at IS NULL
    AND public.has_document_role(id, ARRAY['owner', 'editor'])
)
WITH CHECK (
    public.has_document_role(id, ARRAY['owner', 'editor'])
);

-- Quyền 4: XÓA TÀI LIỆU (DELETE hoặc Soft Delete)
-- Điều kiện: CHỈ duy nhất Chủ sở hữu (Owner) mới có quyền xóa tài liệu
DROP POLICY IF EXISTS "Chỉ Chủ sở hữu được xóa tài liệu" ON public.documents;
CREATE POLICY "Chỉ Chủ sở hữu được xóa tài liệu"
ON public.documents FOR DELETE
TO anon, authenticated
USING (
    public.has_document_role(id, ARRAY['owner'])
);


-- ----------------------------------------------------------------------------
-- POLICIES CHO BẢNG DOCUMENT_PERMISSIONS (QUYỀN CHIA SẺ)
-- ----------------------------------------------------------------------------

-- Quyền xem danh sách chia sẻ: Chủ sở hữu của tài liệu hoặc người được chia sẻ
DROP POLICY IF EXISTS "Xem quyền chia sẻ tài liệu" ON public.document_permissions;
CREATE POLICY "Xem quyền chia sẻ tài liệu"
ON public.document_permissions FOR SELECT
TO anon, authenticated
USING (
    user_id = auth.jwt() ->> 'sub'
    OR lower(user_email) = lower(public.current_user_email())
    OR public.has_document_role(document_id, ARRAY['owner'])
);

-- Quyền thêm quyền chia sẻ: CHỈ Chủ sở hữu của tài liệu mới có quyền chia sẻ cho người khác
DROP POLICY IF EXISTS "Chủ sở hữu được cấp quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu được cấp quyền chia sẻ"
ON public.document_permissions FOR INSERT
TO anon, authenticated
WITH CHECK (
    public.has_document_role(document_id, ARRAY['owner'])
    AND public.is_valid_share_recipient(user_id, user_email)
);

-- Quyền sửa đổi quyền: CHỈ Chủ sở hữu
DROP POLICY IF EXISTS "Chủ sở hữu được sửa quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu được sửa quyền chia sẻ"
ON public.document_permissions FOR UPDATE
TO anon, authenticated
USING (
    public.has_document_role(document_id, ARRAY['owner'])
)
WITH CHECK (
    public.has_document_role(document_id, ARRAY['owner'])
    AND public.is_valid_share_recipient(user_id, user_email)
);

-- Quyền thu hồi quyền chia sẻ: CHỈ Chủ sở hữu
DROP POLICY IF EXISTS "Chủ sở hữu được thu hồi quyền chia sẻ" ON public.document_permissions;
CREATE POLICY "Chủ sở hữu được thu hồi quyền chia sẻ"
ON public.document_permissions FOR DELETE
TO anon, authenticated
USING (
    public.has_document_role(document_id, ARRAY['owner'])
);
