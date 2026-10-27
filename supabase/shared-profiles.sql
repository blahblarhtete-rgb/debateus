-- DebateUs shared profiles
-- Safe additive migration: creates a dedicated table and does not alter existing tables.
CREATE TABLE IF NOT EXISTS public.debateus_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text NOT NULL,
  display_name text NOT NULL DEFAULT '',
  bio text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS debateus_profiles_username_lower_uidx
  ON public.debateus_profiles (lower(username));

ALTER TABLE public.debateus_profiles ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.debateus_profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.debateus_profiles TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'debateus_profiles'
      AND policyname = 'DebateUs profiles are publicly readable'
  ) THEN
    CREATE POLICY "DebateUs profiles are publicly readable"
      ON public.debateus_profiles
      FOR SELECT
      TO anon, authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'debateus_profiles'
      AND policyname = 'Users create their own DebateUs profile'
  ) THEN
    CREATE POLICY "Users create their own DebateUs profile"
      ON public.debateus_profiles
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'debateus_profiles'
      AND policyname = 'Users update their own DebateUs profile'
  ) THEN
    CREATE POLICY "Users update their own DebateUs profile"
      ON public.debateus_profiles
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END
$$;
