-- Create moves table for game history with Realtime support
CREATE TABLE IF NOT EXISTS public.moves (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    game_id UUID NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    move_number INT NOT NULL,
    uci TEXT NOT NULL,
    san TEXT,
    fen_after TEXT NOT NULL,
    player_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_game_move UNIQUE(game_id, move_number)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_moves_game_id ON public.moves(game_id);
CREATE INDEX IF NOT EXISTS idx_moves_created_at ON public.moves(created_at);

-- Enable Row Level Security
ALTER TABLE public.moves ENABLE ROW LEVEL SECURITY;

-- Create policies for moves table
-- Allow authenticated users to read moves for games they participate in
CREATE POLICY "Users can view moves for their games"
    ON public.moves FOR SELECT
    USING (
        game_id IN (
            SELECT id FROM public.games 
            WHERE white_player_id = auth.uid() 
            OR black_player_id = auth.uid()
        )
    );

-- Allow authenticated users to insert moves for games they participate in
CREATE POLICY "Users can insert moves for their games"
    ON public.moves FOR INSERT
    WITH CHECK (
        game_id IN (
            SELECT id FROM public.games 
            WHERE white_player_id = auth.uid() 
            OR black_player_id = auth.uid()
        )
    );

-- Enable Realtime for moves table
ALTER PUBLICATION supabase_realtime ADD TABLE public.moves;

-- Add comments for documentation
COMMENT ON TABLE public.moves IS 'Game move history with Realtime support';
COMMENT ON COLUMN public.moves.uci IS 'Universal Chess Interface notation (e.g., e2e4)';
COMMENT ON COLUMN public.moves.san IS 'Standard Algebraic Notation (e.g., Nf3)';
COMMENT ON COLUMN public.moves.fen_after IS 'Forsyth-Edwards Notation after the move';
