-- Optional second model package for glTF assets.
-- Keeps legacy AC3D package in mo_modelfile unchanged and mandatory.

ALTER TABLE public.fgs_models
  ADD COLUMN IF NOT EXISTS mo_gltf_modelfile character varying;

COMMENT ON COLUMN public.fgs_models.mo_gltf_modelfile IS
  'Optional base64-encoded gzipped tarball containing glTF model package.';
