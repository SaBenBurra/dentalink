-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 037: Oral Diagnoz branşı kaldırıldı
-- ═══════════════════════════════════════════════════════════════════════════════
-- Branşın tedavi türleri silinir ve posts.branch'te değer CHECK ile yasaklanır;
-- case_treatment tür bulamadığı için RPC'ler de 22023 ile reddeder.
-- shortcut: 'oral_diagnoz_uzmani' dental_branch tipinde atıl kalır (enum'dan değer
--   silmek tipi yeniden kurmayı, yani bu tipi kullanan 5 RPC'yi (create_post, update_post,
--   popular_post_ids, case_treatment, promote_other_treatment) düşürüp yeniden
--   yazmayı gerektirir); o RPC'ler bir sonraki sefer zaten değişirken yapılabilir.
-- Önkoşul: bu branştaki postlar önceden silinmiş olmalı (görseller Storage'dan
-- ayrıca kaldırılır); yoksa migration durur.
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.posts WHERE branch = 'oral_diagnoz_uzmani') THEN
    RAISE EXCEPTION 'oral_diagnoz_uzmani branşında post var; önce onları sil';
  END IF;
END $$;

DELETE FROM public.treatment_types WHERE branch = 'oral_diagnoz_uzmani';

ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_branch_not_removed;
ALTER TABLE public.posts ADD CONSTRAINT posts_branch_not_removed
  CHECK (branch IS DISTINCT FROM 'oral_diagnoz_uzmani');
