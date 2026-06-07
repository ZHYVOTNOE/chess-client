-- Add missing columns to games table for draw offers and winner tracking
ALTER TABLE public.games 
ADD COLUMN IF NOT EXISTS draw_offered_by UUID,
ADD COLUMN IF NOT EXISTS winner TEXT;

-- Add comments for documentation
COMMENT ON COLUMN public.games.draw_offered_by IS 'User ID who offered the draw';
COMMENT ON COLUMN public.games.winner IS 'Winner of the game: "white", "black", "draw", or user ID';
