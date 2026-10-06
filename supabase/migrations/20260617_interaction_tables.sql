-- ================================================================
-- Al Arsh — Interaction Tables Migration
-- الجداول: post_likes / post_views / comments + RPCs + Triggers
-- شغّل هذا في Supabase SQL Editor
-- ================================================================

-- ── 1. جدول الإعجابات (post_likes) ──────────────────────────────
CREATE TABLE IF NOT EXISTS post_likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid        NOT NULL REFERENCES posts(id)  ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, user_id)
);

ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anyone can read likes"
  ON post_likes FOR SELECT USING (true);

CREATE POLICY "authenticated users can like"
  ON post_likes FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users can unlike their own likes"
  ON post_likes FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ── 2. جدول المشاهدات (post_views) ──────────────────────────────
-- مفتاح مركّب (post_id + viewer_key) يمنع تكرار المشاهدة
CREATE TABLE IF NOT EXISTS post_views (
  post_id    uuid        NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  viewer_key text        NOT NULL,  -- user_id as text
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, viewer_key)
);

ALTER TABLE post_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anyone can read views"
  ON post_views FOR SELECT USING (true);

CREATE POLICY "anyone can record a view"
  ON post_views FOR INSERT WITH CHECK (true);

-- ── 3. جدول التعليقات (comments) ────────────────────────────────
-- (الجدول موجود مسبقاً، سنضيف فقط RLS إن لم تكن موجودة)
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- يمكن أن نتجاهل الأخطاء إذا كانت الـ Policies موجودة مسبقاً عن طريق تشغيلها يدوياً
-- أو إضافة كود PL/pgSQL للتحقق، ولكن لتسهيل الأمر سأضعها هنا كمرجع:
/*
CREATE POLICY "anyone can read comments" ON comments FOR SELECT USING (true);
CREATE POLICY "authenticated users can comment" ON comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "users can delete own comments" ON comments FOR DELETE TO authenticated USING (auth.uid() = user_id);
*/

-- ── 4. دالة toggle_like — تبديل الإعجاب (منع التكرار) ──────────
CREATE OR REPLACE FUNCTION toggle_like(p_post_id uuid)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_liked   boolean;
  v_count   int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'يجب تسجيل الدخول للإعجاب';
  END IF;

  IF EXISTS (
    SELECT 1 FROM post_likes
    WHERE post_id = p_post_id AND user_id = v_user_id
  ) THEN
    -- إلغاء الإعجاب
    DELETE FROM post_likes
    WHERE post_id = p_post_id AND user_id = v_user_id;

    UPDATE posts
    SET raw_likes = GREATEST(raw_likes - 1, 0)
    WHERE id = p_post_id;

    v_liked := false;
  ELSE
    -- إضافة الإعجاب
    INSERT INTO post_likes (post_id, user_id)
    VALUES (p_post_id, v_user_id);

    UPDATE posts
    SET raw_likes = raw_likes + 1
    WHERE id = p_post_id;

    v_liked := true;
  END IF;

  SELECT raw_likes INTO v_count FROM posts WHERE id = p_post_id;

  RETURN json_build_object('liked', v_liked, 'count', v_count);
END;
$$;

-- ── 5. دالة record_view — تسجيل مشاهدة واحدة لكل مستخدم ────────
CREATE OR REPLACE FUNCTION record_view(p_post_id uuid, p_viewer_key text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rows int;
BEGIN
  INSERT INTO post_views (post_id, viewer_key)
  VALUES (p_post_id, p_viewer_key)
  ON CONFLICT (post_id, viewer_key) DO NOTHING;

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  IF v_rows > 0 THEN
    UPDATE posts SET raw_views = raw_views + 1 WHERE id = p_post_id;
    RETURN true;   -- مشاهدة جديدة
  END IF;

  RETURN false;    -- شوهد مسبقاً
END;
$$;

-- ── 6. Trigger — تحديث raw_comments تلقائياً ───────────────────
CREATE OR REPLACE FUNCTION sync_comment_count()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET raw_comments = raw_comments + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET raw_comments = GREATEST(raw_comments - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS comments_count_trigger ON comments;
CREATE TRIGGER comments_count_trigger
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION sync_comment_count();

-- ── 7. إصلاح raw_likes الحالية (تزامن مع post_likes) ────────────
-- إذا كان raw_likes في posts مختلفاً عن عدد الإعجابات الفعلي
UPDATE posts p
SET raw_likes = (
  SELECT COUNT(*) FROM post_likes WHERE post_id = p.id
);

-- ── 8. إصلاح raw_comments الحالية ───────────────────────────────
UPDATE posts p
SET raw_comments = (
  SELECT COUNT(*) FROM comments WHERE post_id = p.id
);
