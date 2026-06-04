-- =============================================================================
-- UndergroundFM — Database schema
-- Run dit volledig in de Supabase SQL Editor van je project.
-- =============================================================================

-- ─────────────────────────────────────────
-- TABEL: users
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'consumer'
    CHECK (role IN ('consumer', 'artist', 'admin')),
  is_founding_artist BOOLEAN NOT NULL DEFAULT FALSE,
  subscription_status TEXT NOT NULL DEFAULT 'inactive'
    CHECK (subscription_status IN ('active','trial','expired','inactive')),
  revenuecat_user_id TEXT,
  preferred_language TEXT NOT NULL DEFAULT 'nl'
    CHECK (preferred_language IN ('nl','en','es')),
  country TEXT DEFAULT 'NL',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "users_own_row" ON public.users;
CREATE POLICY "users_own_row" ON public.users USING (auth.uid() = id);
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- ─────────────────────────────────────────
-- TABEL: invite_codes
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  created_by UUID REFERENCES public.users(id),
  used_by UUID REFERENCES public.users(id),
  used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  max_uses INTEGER DEFAULT 1,
  use_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "invite_codes_verify" ON public.invite_codes;
CREATE POLICY "invite_codes_verify" ON public.invite_codes
  FOR SELECT USING (is_active = TRUE AND use_count < COALESCE(max_uses, 1));
DROP POLICY IF EXISTS "invite_codes_claim" ON public.invite_codes;
CREATE POLICY "invite_codes_claim" ON public.invite_codes
  FOR UPDATE USING (is_active = TRUE AND use_count < COALESCE(max_uses, 1))
  WITH CHECK (TRUE);

-- ─────────────────────────────────────────
-- TABEL: artists
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.artists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  artist_name TEXT NOT NULL,
  bio TEXT CHECK (char_length(bio) <= 500),
  genre_tags TEXT[] DEFAULT '{}',
  instagram_url TEXT,
  invite_code_used TEXT,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  payout_iban TEXT,
  payout_email TEXT,
  total_earnings_cents BIGINT NOT NULL DEFAULT 0,
  revenue_share_pct DECIMAL(4,2) NOT NULL DEFAULT 0.50
    CHECK (revenue_share_pct BETWEEN 0.10 AND 0.80),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.artists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "artists_public_read" ON public.artists;
CREATE POLICY "artists_public_read" ON public.artists FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "artists_own_write" ON public.artists;
CREATE POLICY "artists_own_write" ON public.artists FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "artists_own_insert" ON public.artists;
CREATE POLICY "artists_own_insert" ON public.artists FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- TABEL: tracks
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID NOT NULL REFERENCES public.artists(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  audio_url TEXT,
  video_url TEXT,
  cloudflare_uid TEXT,
  thumbnail_url TEXT,
  duration INTEGER,
  stream_count BIGINT NOT NULL DEFAULT 0,
  like_count BIGINT NOT NULL DEFAULT 0,
  genre_tags TEXT[] DEFAULT '{}',
  explicit BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'processing'
    CHECK (status IN ('processing','live','rejected','draft','removed')),
  is_exclusive_window BOOLEAN DEFAULT FALSE,
  exclusive_until TIMESTAMPTZ,
  weighted_minutes_total DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tracks_artist ON public.tracks(artist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_status ON public.tracks(status);
CREATE INDEX IF NOT EXISTS idx_tracks_created ON public.tracks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tracks_genre ON public.tracks USING GIN(genre_tags);

ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tracks_public_read" ON public.tracks;
CREATE POLICY "tracks_public_read" ON public.tracks FOR SELECT USING (status = 'live');
DROP POLICY IF EXISTS "tracks_artist_all" ON public.tracks;
CREATE POLICY "tracks_artist_all" ON public.tracks FOR ALL USING (
  artist_id IN (SELECT id FROM public.artists WHERE user_id = auth.uid())
);

-- ─────────────────────────────────────────
-- TABEL: stream_logs
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.stream_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  listened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duration_seconds INTEGER NOT NULL,
  completion_pct DECIMAL(5,2),
  weighted_score DECIMAL(6,4),
  source TEXT DEFAULT 'direct',
  device_type TEXT
);

CREATE INDEX IF NOT EXISTS idx_stream_logs_track ON public.stream_logs(track_id);
CREATE INDEX IF NOT EXISTS idx_stream_logs_user ON public.stream_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_stream_logs_listened ON public.stream_logs(listened_at DESC);

ALTER TABLE public.stream_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "stream_logs_insert" ON public.stream_logs;
CREATE POLICY "stream_logs_insert" ON public.stream_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- TABEL: subscriptions
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id),
  revenuecat_sub_id TEXT UNIQUE,
  plan TEXT DEFAULT 'monthly_5eur',
  status TEXT NOT NULL DEFAULT 'inactive'
    CHECK (status IN ('active','trial','cancelled','expired','inactive')),
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  store TEXT CHECK (store IN ('apple','google','web')),
  store_fee_pct DECIMAL(4,2) DEFAULT 0.30,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "subscriptions_own" ON public.subscriptions;
CREATE POLICY "subscriptions_own" ON public.subscriptions USING (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- TABELLEN: playlists, playlist_tracks, follows, likes, monthly_payouts
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  track_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Bestaande projecten: voeg de description-kolom toe als die nog niet bestaat.
ALTER TABLE public.playlists ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "playlists_read" ON public.playlists;
CREATE POLICY "playlists_read" ON public.playlists FOR SELECT USING (is_public = TRUE OR auth.uid() = user_id);
DROP POLICY IF EXISTS "playlists_write" ON public.playlists;
CREATE POLICY "playlists_write" ON public.playlists FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.playlist_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id UUID NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL DEFAULT 0,
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(playlist_id, track_id)
);

CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  artist_id UUID NOT NULL REFERENCES public.artists(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, artist_id)
);

CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, track_id)
);

CREATE TABLE IF NOT EXISTS public.monthly_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID NOT NULL REFERENCES public.artists(id),
  period_month TEXT NOT NULL,
  total_weighted_seconds DECIMAL,
  platform_total_seconds DECIMAL,
  pool_amount_cents BIGINT,
  payout_amount_cents BIGINT,
  revenue_share_pct DECIMAL(4,2),
  status TEXT NOT NULL DEFAULT 'calculated'
    CHECK (status IN ('calculated','approved','paid','failed')),
  paid_at TIMESTAMPTZ,
  UNIQUE(artist_id, period_month)
);

-- ─────────────────────────────────────────
-- TABEL: view_events  (luister-analytics — gebruikt door ViewTracker + profiel-stats)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.view_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  session_id TEXT NOT NULL,
  seconds_watched INTEGER NOT NULL DEFAULT 0,
  completion_pct DECIMAL(6,4),
  weighted_score DECIMAL(6,4),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_view_events_track ON public.view_events(track_id);
CREATE INDEX IF NOT EXISTS idx_view_events_user ON public.view_events(user_id);
CREATE INDEX IF NOT EXISTS idx_view_events_created ON public.view_events(created_at DESC);

ALTER TABLE public.view_events ENABLE ROW LEVEL SECURITY;
-- ViewTracker post anoniem (alleen apikey) — insert open houden.
DROP POLICY IF EXISTS "view_events_insert" ON public.view_events;
CREATE POLICY "view_events_insert" ON public.view_events FOR INSERT WITH CHECK (TRUE);
-- Stats zijn aggregaat-analytics — lezen toegestaan.
DROP POLICY IF EXISTS "view_events_read" ON public.view_events;
CREATE POLICY "view_events_read" ON public.view_events FOR SELECT USING (TRUE);

-- ─────────────────────────────────────────
-- RLS: follows + likes (waren nog niet beveiligd)
-- ─────────────────────────────────────────
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "follows_public_read" ON public.follows;
CREATE POLICY "follows_public_read" ON public.follows FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS "follows_own_write" ON public.follows;
CREATE POLICY "follows_own_write" ON public.follows FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "follows_own_delete" ON public.follows;
CREATE POLICY "follows_own_delete" ON public.follows FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "likes_own_read" ON public.likes;
CREATE POLICY "likes_own_read" ON public.likes FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "likes_own_write" ON public.likes;
CREATE POLICY "likes_own_write" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "likes_own_delete" ON public.likes;
CREATE POLICY "likes_own_delete" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- RPC: increment_stream_count
-- Verhoogt de afspeelteller atomair. SECURITY DEFINER zodat ook anonieme
-- luisteraars (ViewTracker post met alleen apikey) de teller mogen ophogen,
-- ondanks de tracks RLS die alleen de eigenaar laat schrijven.
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.increment_stream_count(track_id_input UUID)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $
  UPDATE public.tracks
     SET stream_count = stream_count + 1
   WHERE id = track_id_input;
$;

GRANT EXECUTE ON FUNCTION public.increment_stream_count(UUID) TO anon, authenticated;

-- ─────────────────────────────────────────
-- Test invite codes (optioneel — verwijder na test)
-- ─────────────────────────────────────────
INSERT INTO public.invite_codes (code, is_active, max_uses)
VALUES ('UNDER001', TRUE, 1), ('FOUND-001', TRUE, 1)
ON CONFLICT (code) DO NOTHING;
