BEGIN;

ALTER TABLE public.children
  DROP CONSTRAINT IF EXISTS children_gender_check;

ALTER TABLE public.children
  ADD CONSTRAINT children_gender_check
  CHECK (
    gender IS NULL OR gender IN (
      'male',
      'female',
      'laki-laki',
      'perempuan',
      'Laki-laki',
      'Perempuan'
    )
  );

COMMIT;