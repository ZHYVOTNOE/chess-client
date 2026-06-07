-- Drop existing function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.calculate_rating_after_game CASCADE;

-- Create RPC function to calculate rating after game ends
CREATE OR REPLACE FUNCTION public.calculate_rating_after_game(
    p_game_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_white_id UUID;
    v_black_id UUID;
    v_variant TEXT;
    v_time_control TEXT;
    v_status TEXT;
    v_result TEXT;
    v_white_rating INT;
    v_black_rating INT;
    v_white_rd FLOAT;
    v_black_rd FLOAT;
    v_white_new_rating INT;
    v_black_new_rating INT;
    v_winner TEXT;
BEGIN
    -- Get game details
    SELECT 
        white_id,
        black_id,
        variant,
        time_control,
        status,
        result,
        winner
    INTO 
        v_white_id,
        v_black_id,
        v_variant,
        v_time_control,
        v_status,
        v_result,
        v_winner
    FROM public.games
    WHERE id = p_game_id;

    IF v_white_id IS NULL THEN
        RAISE EXCEPTION 'Game not found';
    END IF;

    -- Get current ratings
    SELECT rating, rd INTO v_white_rating, v_white_rd
    FROM public.ratings
    WHERE user_id = v_white_id 
      AND variant_key = v_variant
      AND time_control_type = v_time_control;

    SELECT rating, rd INTO v_black_rating, v_black_rd
    FROM public.ratings
    WHERE user_id = v_black_id 
      AND variant_key = v_variant
      AND time_control_type = v_time_control;

    -- Default ratings if not found
    IF v_white_rating IS NULL THEN v_white_rating := 1500; v_white_rd := 350; END IF;
    IF v_black_rating IS NULL THEN v_black_rating := 1500; v_black_rd := 350; END IF;

    -- Calculate new ratings using Glicko-2 simplified
    -- This is a simplified rating calculation - adjust based on your rating system
    CASE 
        WHEN v_winner = 'white' OR (v_result ILIKE '%white wins%') THEN
            v_white_new_rating := v_white_rating + 25;
            v_black_new_rating := v_black_rating - 25;
        WHEN v_winner = 'black' OR (v_result ILIKE '%black wins%') THEN
            v_white_new_rating := v_white_rating - 25;
            v_black_new_rating := v_black_rating + 25;
        WHEN v_result ILIKE '%draw%' OR v_status = 'draw' THEN
            v_white_new_rating := v_white_rating + 0;
            v_black_new_rating := v_black_rating + 0;
        ELSE
            -- Default: no rating change
            v_white_new_rating := v_white_rating;
            v_black_new_rating := v_black_rating;
    END CASE;

    -- Update ratings
    INSERT INTO public.ratings (user_id, variant_key, time_control_type, rating, rd, last_updated_at)
    VALUES (v_white_id, v_variant, v_time_control, v_white_new_rating, v_white_rd, NOW())
    ON CONFLICT (user_id, variant_key, time_control_type) 
    DO UPDATE SET 
        rating = v_white_new_rating,
        rd = v_white_rd,
        last_updated_at = NOW();

    INSERT INTO public.ratings (user_id, variant_key, time_control_type, rating, rd, last_updated_at)
    VALUES (v_black_id, v_variant, v_time_control, v_black_new_rating, v_black_rd, NOW())
    ON CONFLICT (user_id, variant_key, time_control_type) 
    DO UPDATE SET 
        rating = v_black_new_rating,
        rd = v_black_rd,
        last_updated_at = NOW();

    -- Record rating history
    INSERT INTO public.rating_history (
        user_id, 
        game_id, 
        old_rating, 
        new_rating, 
        variant_key, 
        time_control_type,
        created_at
    ) VALUES (
        v_white_id, 
        p_game_id, 
        v_white_rating, 
        v_white_new_rating, 
        v_variant, 
        v_time_control,
        NOW()
    );

    INSERT INTO public.rating_history (
        user_id, 
        game_id, 
        old_rating, 
        new_rating, 
        variant_key, 
        time_control_type,
        created_at
    ) VALUES (
        v_black_id, 
        p_game_id, 
        v_black_rating, 
        v_black_new_rating, 
        v_variant, 
        v_time_control,
        NOW()
    );

    -- Update profiles with game statistics
    UPDATE public.profiles
    SET 
        games_played = COALESCE(games_played, 0) + 1,
        rating = v_white_new_rating,
        last_rating_change_at = NOW()
    WHERE id = v_white_id;

    UPDATE public.profiles
    SET 
        games_played = COALESCE(games_played, 0) + 1,
        rating = v_black_new_rating,
        last_rating_change_at = NOW()
    WHERE id = v_black_id;

    -- Update win/loss counts
    IF v_winner = 'white' OR (v_result ILIKE '%white wins%') THEN
        UPDATE public.profiles SET games_won = COALESCE(games_won, 0) + 1 WHERE id = v_white_id;
        UPDATE public.profiles SET games_lost = COALESCE(games_lost, 0) + 1 WHERE id = v_black_id;
    ELSIF v_winner = 'black' OR (v_result ILIKE '%black wins%') THEN
        UPDATE public.profiles SET games_lost = COALESCE(games_lost, 0) + 1 WHERE id = v_white_id;
        UPDATE public.profiles SET games_won = COALESCE(games_won, 0) + 1 WHERE id = v_black_id;
    ELSIF v_result ILIKE '%draw%' OR v_status = 'draw' THEN
        UPDATE public.profiles SET games_drawn = COALESCE(games_drawn, 0) + 1 WHERE id = v_white_id;
        UPDATE public.profiles SET games_drawn = COALESCE(games_drawn, 0) + 1 WHERE id = v_black_id;
    END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.calculate_rating_after_game TO authenticated;
