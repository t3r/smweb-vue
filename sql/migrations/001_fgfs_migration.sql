-- User roles for authorization (normal user, reviewer, admin).
-- Run this migration to enable role-based access.
-- eu_authority in fgs_extuserids: 1 = GitHub, 5 = GitLab (2–4 reserved in legacy schema).

CREATE TABLE IF NOT EXISTS public.fgs_user_roles (
    au_id integer NOT NULL PRIMARY KEY REFERENCES public.fgs_authors(au_id) ON DELETE CASCADE,
    role character varying(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'reviewer', 'admin'))
);

-- Soft delete for models: set mo_deleted to a timestamp to mark as deleted; NULL = not deleted.
ALTER TABLE public.fgs_models ADD COLUMN IF NOT EXISTS mo_deleted timestamp without time zone;

-- mo_modified_by: author who last modified or deleted the model (references fgs_authors).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fgs_models_mo_modified_by_fkey'
    AND conrelid = 'public.fgs_models'::regclass
  ) THEN
    ALTER TABLE public.fgs_models
      ADD CONSTRAINT fgs_models_mo_modified_by_fkey
      FOREIGN KEY (mo_modified_by) REFERENCES public.fgs_authors(au_id);
  END IF;
END $$;
