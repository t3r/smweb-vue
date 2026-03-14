-- SQS-style visibility: messages stay in the table until explicitly deleted; receive sets in-flight window + receipt handle.

ALTER TABLE public.fgs_email_queue
    ADD COLUMN IF NOT EXISTS eq_in_flight_until TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS eq_receipt_handle UUID NULL,
    ADD COLUMN IF NOT EXISTS eq_result_status VARCHAR(32) NULL,
    ADD COLUMN IF NOT EXISTS eq_result_detail TEXT NULL,
    ADD COLUMN IF NOT EXISTS eq_result_at TIMESTAMPTZ NULL;

DROP INDEX IF EXISTS idx_fgs_email_queue_pending;

ALTER TABLE public.fgs_email_queue DROP COLUMN IF EXISTS eq_processed_at;

-- Receivable rows are filtered at query time (visibility); index supports ordering + attempt cap.
CREATE INDEX IF NOT EXISTS idx_fgs_email_queue_receivable
    ON public.fgs_email_queue (eq_created_at ASC)
    WHERE eq_attempts < 5;

COMMENT ON COLUMN public.fgs_email_queue.eq_in_flight_until IS 'Until this time the message is hidden from other consumers (visibility timeout).';
COMMENT ON COLUMN public.fgs_email_queue.eq_receipt_handle IS 'Set on receive; required for delete.';
COMMENT ON COLUMN public.fgs_email_queue.eq_result_status IS 'Reserved for optional future use (not written by API).';
