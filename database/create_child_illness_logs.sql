BEGIN;

CREATE TABLE IF NOT EXISTS public.child_illness_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
  illness_type TEXT NOT NULL CHECK (length(trim(illness_type)) > 0),
  symptoms TEXT[] NOT NULL DEFAULT '{}',
  treatment_given TEXT,
  is_referred_to_hospital BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.child_illness_logs ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.can_access_child_illness_log(p_child_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.children AS child
    WHERE child.id = p_child_id
      AND child.parent_id = (SELECT auth.uid())
  );
$function$;

REVOKE ALL ON FUNCTION public.can_access_child_illness_log(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_access_child_illness_log(UUID) TO authenticated;

DROP POLICY IF EXISTS "Parents can view their children's illness logs"
  ON public.child_illness_logs;
CREATE POLICY "Parents can view their children's illness logs"
  ON public.child_illness_logs FOR SELECT TO authenticated
  USING (public.can_access_child_illness_log(child_id));

DROP POLICY IF EXISTS "Parents can add their children's illness logs"
  ON public.child_illness_logs;
CREATE POLICY "Parents can add their children's illness logs"
  ON public.child_illness_logs FOR INSERT TO authenticated
  WITH CHECK (public.can_access_child_illness_log(child_id));

GRANT SELECT, INSERT ON public.child_illness_logs TO authenticated;

COMMIT;