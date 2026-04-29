-- Account merge: email-verified flow to combine two fgs_authors rows (see accountMergeService).
-- Intentionally no FK to fgs_authors so confirmed/cancelled rows remain as audit after author delete.

CREATE TABLE IF NOT EXISTS public.fgs_account_merge_requests (
  amr_id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  amr_source_author_id        integer NOT NULL,
  amr_target_author_id        integer NOT NULL,
  amr_target_email_at_create  character varying(64) NOT NULL,
  amr_token_hash              bytea NOT NULL,
  amr_created_at              timestamptz NOT NULL DEFAULT now(),
  amr_expires_at              timestamptz NOT NULL,
  amr_confirmed_at            timestamptz,
  amr_cancelled_at            timestamptz,
  amr_keeper_author_id        integer,
  CHECK (amr_source_author_id <> amr_target_author_id)
);

CREATE INDEX IF NOT EXISTS idx_amr_source ON public.fgs_account_merge_requests (amr_source_author_id);
CREATE INDEX IF NOT EXISTS idx_amr_target ON public.fgs_account_merge_requests (amr_target_author_id);
CREATE INDEX IF NOT EXISTS idx_amr_token_hash ON public.fgs_account_merge_requests (amr_token_hash);

-- At most one "open" request per (source, target) pair (cancel expired rows in app before insert).
CREATE UNIQUE INDEX IF NOT EXISTS uq_amr_open_pair
  ON public.fgs_account_merge_requests (amr_source_author_id, amr_target_author_id)
  WHERE amr_confirmed_at IS NULL AND amr_cancelled_at IS NULL;

COMMENT ON TABLE public.fgs_account_merge_requests IS 'OAuth account merge requests; token stored as sha256 only';
