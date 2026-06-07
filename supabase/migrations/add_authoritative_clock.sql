-- Add authoritative chess clock fields to games table
ALTER TABLE public.games 
ADD COLUMN IF NOT EXISTS white_remaining_time INTERVAL DEFAULT INTERVAL '0',
ADD COLUMN IF NOT EXISTS black_remaining_time INTERVAL DEFAULT INTERVAL '0',
ADD COLUMN IF NOT EXISTS time_control_base INTERVAL DEFAULT INTERVAL '0',
ADD COLUMN IF NOT EXISTS time_control_increment INTERVAL DEFAULT INTERVAL '0',
ADD COLUMN IF NOT EXISTS last_move_at TIMESTAMP WITH TIME ZONE;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_games_last_move_at ON public.games(last_move_at);
CREATE INDEX IF NOT EXISTS idx_games_status ON public.games(status);

-- Add comments for documentation
COMMENT ON COLUMN public.games.white_remaining_time IS 'White player remaining time (authoritative)';
COMMENT ON COLUMN public.games.black_remaining_time IS 'Black player remaining time (authoritative)';
COMMENT ON COLUMN public.games.time_control_base IS 'Base time for each player';
COMMENT ON COLUMN public.games.time_control_increment IS 'Increment per move';
COMMENT ON COLUMN public.games.last_move_at IS 'Timestamp of the last move (for clock calculation)';
