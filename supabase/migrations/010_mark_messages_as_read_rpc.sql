-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 010: Mark Messages As Read RPC
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.mark_messages_as_read(p_conversation_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user1_id uuid;
  v_user2_id uuid;
BEGIN
  -- Mark all messages received by the current user in this conversation as read
  UPDATE messages
  SET is_read = true
  WHERE conversation_id = p_conversation_id
    AND receiver_id = auth.uid()
    AND is_read = false;

  -- Reset unread count for the current user in the conversation
  SELECT user1_id, user2_id INTO v_user1_id, v_user2_id
  FROM conversations
  WHERE id = p_conversation_id;

  IF auth.uid() = v_user1_id THEN
    UPDATE conversations
    SET user1_unread_count = 0
    WHERE id = p_conversation_id;
  ELSIF auth.uid() = v_user2_id THEN
    UPDATE conversations
    SET user2_unread_count = 0
    WHERE id = p_conversation_id;
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.mark_messages_as_read(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mark_messages_as_read(uuid) TO authenticated;
