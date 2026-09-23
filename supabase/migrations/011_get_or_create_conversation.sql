-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 011: Get or Create Conversation RPC
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Create a unique index on the ordered pair of user IDs to prevent duplicate conversations
CREATE UNIQUE INDEX IF NOT EXISTS unique_conversation_users 
ON public.conversations(LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id));

-- 2. Create RPC for atomic get-or-create of conversations
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(p_other_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conv_id uuid;
  v_user1 uuid;
  v_user2 uuid;
BEGIN
  -- Always order the users (smallest UUID first) to match the unique index
  v_user1 := LEAST(auth.uid(), p_other_user_id);
  v_user2 := GREATEST(auth.uid(), p_other_user_id);

  -- Attempt to insert. If it exists (violates unique index), do nothing
  INSERT INTO public.conversations (user1_id, user2_id)
  VALUES (v_user1, v_user2)
  ON CONFLICT (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)) DO NOTHING
  RETURNING id INTO v_conv_id;

  -- If insert did nothing (row already existed), select the existing ID
  IF v_conv_id IS NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE user1_id = v_user1 AND user2_id = v_user2;
  END IF;

  RETURN v_conv_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_or_create_conversation(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(uuid) TO authenticated;
