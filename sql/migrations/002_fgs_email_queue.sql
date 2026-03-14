-- Asynchronous outbound email notifications: store event type + minimal JSON payload only.
-- After migration 003, consumers use authenticated API /api/email-queue/* (SQS-style receive / result / delete).

CREATE TABLE IF NOT EXISTS public.fgs_email_queue (
    eq_id SERIAL PRIMARY KEY,
    eq_event_type VARCHAR(80) NOT NULL,
    eq_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    eq_created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    eq_processed_at TIMESTAMPTZ NULL,
    eq_attempts INT NOT NULL DEFAULT 0,
    eq_last_error TEXT NULL
);

CREATE INDEX IF NOT EXISTS idx_fgs_email_queue_pending
    ON public.fgs_email_queue (eq_created_at ASC)
    WHERE eq_processed_at IS NULL;

COMMENT ON TABLE public.fgs_email_queue IS 'Pending outbound emails; payload holds only keys needed to build body/recipients when sending.';
COMMENT ON COLUMN public.fgs_email_queue.eq_event_type IS 'Stable event name, e.g. position_request.created';
COMMENT ON COLUMN public.fgs_email_queue.eq_payload IS 'Minimal JSON: ids, sig, type, short strings — not full email body.';
