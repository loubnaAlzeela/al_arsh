-- The gifts table's gift_type CHECK constraint was created with placeholder
-- values ('spark','crown','flame','bolt') that were never used by the app.
-- The real gift catalog (lib/features/gifts/data/gift_package.dart) and the
-- send_gift edge function both use 'coffee','flowers','mic','car'. Every
-- insert into gifts therefore violated the CHECK constraint and silently
-- failed (the edge function doesn't check the insert error), so no gift
-- was ever actually recorded even when crowns were deducted successfully.
ALTER TABLE public.gifts DROP CONSTRAINT IF EXISTS gifts_gift_type_check;

ALTER TABLE public.gifts
  ADD CONSTRAINT gifts_gift_type_check
  CHECK (gift_type IN ('coffee','flowers','mic','car'));
