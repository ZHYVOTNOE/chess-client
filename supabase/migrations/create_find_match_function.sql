-- Drop existing function if it exists to avoid conflicts
DROP FUNCTION IF EXISTS public.find_match CASCADE;

-- Create RPC function to find match (wrapper for enter_matchmaking_queue)
CREATE OR REPLACE FUNCTION public.find_match(
    p_user_id UUID,
    p_variant_key TEXT,
    p_time_control_type TEXT,
    p_min_rating INTEGER,
    p_max_rating INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
    v_user_rating INTEGER;
BEGIN
    -- Get user's current rating (use average of min/max if not available)
    v_user_rating := (p_min_rating + p_max_rating) / 2;
    
    -- Call the existing enter_matchmaking_queue function
    SELECT public.enter_matchmaking_queue(
        p_variant_key,
        p_time_control_type,
        v_user_rating
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.find_match TO authenticated;
