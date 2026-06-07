-- Drop existing function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.make_move_authoritative CASCADE;

-- Create RPC function for atomic move processing with authoritative clock
CREATE OR REPLACE FUNCTION public.make_move_authoritative(
    p_game_id UUID,
    p_uci TEXT,
    p_san TEXT,
    p_fen_after TEXT,
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_game RECORD;
    v_move_number INT;
    v_time_spent INTERVAL;
    v_current_turn TEXT;
    v_is_white BOOLEAN;
    v_result JSONB;
BEGIN
    -- Lock the game row for atomic update
    SELECT * INTO v_game
    FROM public.games
    WHERE id = p_game_id
    FOR UPDATE;

    IF v_game IS NULL THEN
        RAISE EXCEPTION 'Game not found';
    END IF;

    -- Validate that the user is a player in this game
    IF v_game.white_player_id != p_user_id AND v_game.black_player_id != p_user_id THEN
        RAISE EXCEPTION 'User is not a player in this game';
    END IF;

    -- Validate game status
    IF v_game.status != 'in_progress' THEN
        RAISE EXCEPTION 'Game is not in progress';
    END IF;

    -- Determine whose turn it is based on FEN
    -- FEN format: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
    -- The second field indicates turn: 'w' for white, 'b' for black
    v_current_turn := SUBSTRING(v_game.fen FROM '([wb])');
    v_is_white := (v_current_turn = 'w');

    -- Validate that it's the user's turn
    IF v_is_white AND v_game.white_player_id != p_user_id THEN
        RAISE EXCEPTION 'Not white player turn';
    END IF;
    
    IF NOT v_is_white AND v_game.black_player_id != p_user_id THEN
        RAISE EXCEPTION 'Not black player turn';
    END IF;

    -- Calculate time spent since last move
    IF v_game.last_move_at IS NOT NULL THEN
        v_time_spent := NOW() - v_game.last_move_at;
    ELSE
        v_time_spent := INTERVAL '0';
    END IF;

    -- Calculate move number
    SELECT COALESCE(MAX(move_number), 0) + 1 INTO v_move_number
    FROM public.moves
    WHERE game_id = p_game_id;

    -- Insert move into moves table
    INSERT INTO public.moves (
        game_id,
        move_number,
        uci,
        san,
        fen_after,
        player_id,
        created_at
    ) VALUES (
        p_game_id,
        v_move_number,
        p_uci,
        p_san,
        p_fen_after,
        p_user_id,
        NOW()
    );

    -- Update game state with authoritative clock
    UPDATE public.games
    SET 
        fen = p_fen_after,
        last_move_at = NOW(),
        white_remaining_time = CASE 
            WHEN v_is_white THEN 
                GREATEST(INTERVAL '0', v_game.white_remaining_time - v_time_spent + v_game.time_control_increment)
            ELSE 
                v_game.white_remaining_time
        END,
        black_remaining_time = CASE 
            WHEN NOT v_is_white THEN 
                GREATEST(INTERVAL '0', v_game.black_remaining_time - v_time_spent + v_game.time_control_increment)
            ELSE 
                v_game.black_remaining_time
        END
    WHERE id = p_game_id;

    -- Check for timeout
    SELECT * INTO v_game
    FROM public.games
    WHERE id = p_game_id;

    v_result := jsonb_build_object(
        'success', true,
        'game_id', v_game.id,
        'fen', v_game.fen,
        'white_remaining_time', EXTRACT(EPOCH FROM v_game.white_remaining_time),
        'black_remaining_time', EXTRACT(EPOCH FROM v_game.black_remaining_time),
        'last_move_at', v_game.last_move_at,
        'move_number', v_move_number
    );

    -- Check if game ended due to timeout
    IF v_game.white_remaining_time <= INTERVAL '0' THEN
        UPDATE public.games
        SET 
            status = 'finished',
            winner = 'black'
        WHERE id = p_game_id;
        v_result := v_result || jsonb_build_object('game_over', true, 'winner', 'black', 'reason', 'timeout');
    ELSIF v_game.black_remaining_time <= INTERVAL '0' THEN
        UPDATE public.games
        SET 
            status = 'finished',
            winner = 'white'
        WHERE id = p_game_id;
        v_result := v_result || jsonb_build_object('game_over', true, 'winner', 'white', 'reason', 'timeout');
    END IF;

    RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.make_move_authoritative TO authenticated;
