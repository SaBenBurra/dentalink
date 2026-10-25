-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 019: storage boyut limitleri (Faz 2, görsel sıkıştırma)
-- ═══════════════════════════════════════════════════════════════════════════════
-- İstemci vaka görsellerini 2048px WebP'ye, avatarları 512px JPEG'e çevirir;
-- tipik dosya ~1MB altındadır. Sunucu sınırı 2MB: istemci atlatılsa da büyük
-- dosya kabul edilmez. post-images önceden 5MB (004), avatars limitsizdi (012).
-- ═══════════════════════════════════════════════════════════════════════════════

UPDATE storage.buckets
SET file_size_limit = 2097152
WHERE id IN ('post-images', 'avatars');
