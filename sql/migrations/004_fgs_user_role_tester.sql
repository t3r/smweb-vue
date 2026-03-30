-- Add "tester" role (submission API access; see requireRole('tester') on POST /api/submissions/*).

ALTER TABLE public.fgs_user_roles DROP CONSTRAINT IF EXISTS fgs_user_roles_role_check;
ALTER TABLE public.fgs_user_roles
  ADD CONSTRAINT fgs_user_roles_role_check
  CHECK (role IN ('user', 'reviewer', 'tester', 'admin'));
