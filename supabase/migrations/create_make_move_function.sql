-- Drop existing function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.make_move CASCADE;

-- Create RPC function to make a move and update game state
CREATE OR REPLACE FUNCTION public.make_move(
    p_game_id UUID,
    p_move TEXT,
    p_fen TEXT,
    p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_fen TEXT;
    v_move_number INT;
    v_white_time INTERVAL;
    v_black_time INTERVAL;
BEGIN
    -- Get current game state
    SELECT fen INTO v_current_fen
    FROM public.games
    WHERE id = p_game_id
    FOR UPDATE;

    IF v_current_fen IS NULL THEN
        RAISE EXCEPTION 'Game not found';
    END IF;

    -- Calculate move number (count existing moves + 1)
    SELECT COALESCE(MAX(move_number), 0) + 1 INTO v_move_number
    FROM public.moves
    WHERE game_id = p_game_id;

    -- Insert move into moves table
    INSERT INTO public.moves (
        game_id,
        move_number,
        uci,
        fen_after,
        created_at
    ) VALUES (
        p_game_id,
        v_move_number,
        p_move,
        p_fen,
        NOW()
    );

    -- Update game FEN and last move timestamp
    UPDATE public.games
    SET 
        fen = p_fen,
        last_move_at = NOW()
    WHERE id = p_game_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.make_move TO authenticated;
