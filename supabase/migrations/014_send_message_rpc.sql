-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 014: send_message RPC (DATA-10, SEC-2 kalıcı çözüm)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Sohbet bulma/oluşturma ve mesaj ekleme tek işlemde. Mesaj eklenemezse sohbet
-- de oluşmaz, listede boş sohbet kalmaz. İstemci messages'a doğrudan yazamaz;
-- gönderen her zaman auth.uid(), sohbet her zaman {gönderen, alıcı} çifti.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.send_message(p_receiver_id uuid, p_content text)
RETURNS public.messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_content text := btrim(p_content);
  v_user1   uuid;
  v_user2   uuid;
  v_conv_id uuid;
  v_msg     public.messages;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_receiver_id IS NULL OR p_receiver_id = v_uid THEN
    RAISE EXCEPTION 'invalid receiver' USING ERRCODE = '22023';
  END IF;
  IF v_content IS NULL OR v_content = '' OR char_length(v_content) > 2000 THEN
    RAISE EXCEPTION 'invalid content' USING ERRCODE = '22023';
  END IF;

  v_user1 := LEAST(v_uid, p_receiver_id);
  v_user2 := GREATEST(v_uid, p_receiver_id);

  INSERT INTO public.conversations (user1_id, user2_id)
  VALUES (v_user1, v_user2)
  ON CONFLICT (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)) DO NOTHING
  RETURNING id INTO v_conv_id;

  IF v_conv_id IS NULL THEN
    -- 012 öncesi sırasız eklenmiş çiftler de bulunsun.
    SELECT id INTO v_conv_id
      FROM public.conversations
     WHERE LEAST(user1_id, user2_id) = v_user1
       AND GREATEST(user1_id, user2_id) = v_user2;
  END IF;

  INSERT INTO public.messages (conversation_id, sender_id, receiver_id, content)
  VALUES (v_conv_id, v_uid, p_receiver_id, v_content)
  RETURNING * INTO v_msg;

  RETURN v_msg;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.send_message(uuid, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.send_message(uuid, text) TO authenticated;

-- Doğrudan insert ve mesajsız sohbet oluşturma kapanır.
DROP POLICY IF EXISTS "messages_insert_own" ON public.messages;
REVOKE INSERT ON public.messages FROM authenticated;
DROP FUNCTION IF EXISTS public.get_or_create_conversation(uuid);

-- Önceki iki adımlı akıştan kalan mesajsız sohbetler.
DELETE FROM public.conversations c
 WHERE c.last_message_at IS NULL
   AND NOT EXISTS (SELECT 1 FROM public.messages m WHERE m.conversation_id = c.id);
