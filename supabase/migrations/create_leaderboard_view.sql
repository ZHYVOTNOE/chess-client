-- Create leaderboard view that joins ratings and profiles
CREATE OR REPLACE VIEW leaderboard AS
SELECT 
    r.user_id,
    p.nickname,
    p.avatar_url,
    p.title,
    p.country_code,
    r.rating,
    r.variant_key,
    r.time_control_type
FROM ratings r
JOIN profiles p ON r.user_id = p.id
WHERE r.rating IS NOT NULL;
