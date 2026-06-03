-- Improved matchmaking function with FOR UPDATE SKIP LOCKED and mutual rating check
CREATE OR REPLACE FUNCTION public.enter_matchmaking_queue(
    p_variant_key TEXT,
    p_time_control_type TEXT,
    p_rating INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_opponent_id UUID;
    v_opponent_rating INTEGER;
    v_game_id UUID;
    v_rating_diff INTEGER;
BEGIN
    -- Validate input
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('error', 'User not authenticated', 'match_found', false);
    END IF;

    -- Find an opponent with mutual rating check using FOR UPDATE SKIP LOCKED
    -- This prevents race conditions where two players grab the same opponent
    SELECT user_id, rating INTO v_opponent_id, v_opponent_rating
    FROM public.matchmaking_queue
    WHERE variant_key = p_variant_key 
      AND time_control_type = p_time_control_type
      AND user_id != v_user_id
      -- Mutual rating check: both players must be within 200 points of each other
      AND ABS(rating - p_rating) <= 200
    ORDER BY entered_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_opponent_id IS NOT NULL THEN
        -- Remove BOTH users from the queue immediately
        DELETE FROM public.matchmaking_queue 
        WHERE user_id = v_opponent_id OR user_id = v_user_id;
        
        -- Randomly assign colors
        IF random() > 0.5 THEN
            INSERT INTO public.games (white_id, black_id, variant, time_control, status, fen)
            VALUES (v_opponent_id, v_user_id, p_variant_key, p_time_control_type, 'in_progress', NULL)
            RETURNING id INTO v_game_id;
        ELSE
            INSERT INTO public.games (white_id, black_id, variant, time_control, status, fen)
            VALUES (v_user_id, v_opponent_id, p_variant_key, p_time_control_type, 'in_progress', NULL)
            RETURNING id INTO v_game_id;
        END IF;

        -- Return game_id and match_found flag
        RETURN jsonb_build_object(
            'game_id', v_game_id, 
            'match_found', true,
            'white_id', CASE WHEN random() > 0.5 THEN v_user_id ELSE v_opponent_id END,
            'black_id', CASE WHEN random() > 0.5 THEN v_opponent_id ELSE v_user_id END
        );
    ELSE
        -- No match found, add user to queue
        INSERT INTO public.matchmaking_queue (user_id, variant_key, time_control_type, rating, entered_at)
        VALUES (v_user_id, p_variant_key, p_time_control_type, p_rating, NOW())
        ON CONFLICT (user_id) DO UPDATE SET 
            entered_at = NOW(),
            rating = p_rating,
            variant_key = p_variant_key,
            time_control_type = p_time_control_type;
        
        RETURN jsonb_build_object('match_found', false);
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.enter_matchmaking_queue TO authenticated;
