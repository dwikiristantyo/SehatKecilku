-- 1. Create PROFILES Table (Terhubung ke Supabase Auth)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(50) UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  birth_date DATE,
  phone_number TEXT,
  relationship VARCHAR(20) CHECK (relationship IN ('mother', 'father', 'guardian')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create CHILDREN Table
CREATE TABLE public.children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  gender VARCHAR(10) CHECK (
    gender IN ('male', 'female', 'laki-laki', 'perempuan', 'Laki-laki', 'Perempuan')
  ),
  birth_date DATE NOT NULL,
  birth_weight_kg NUMERIC(4,2),
  birth_length_cm NUMERIC(4,2),
  head_circumference_cm NUMERIC(4,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create GROWTH_RECORDS Table (KMS & Pencatatan Nakes)
CREATE TABLE public.growth_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  recorded_at DATE NOT NULL DEFAULT CURRENT_DATE,
  weight_kg NUMERIC(4,2) NOT NULL,
  height_cm NUMERIC(4,2) NOT NULL,
  head_circumference_cm NUMERIC(4,2),
  z_score_weight NUMERIC(4,2),
  healthcare_provider_name TEXT,
  healthcare_provider_type VARCHAR(20) CHECK (healthcare_provider_type IN ('pediatrician', 'midwife', 'general_practitioner', 'nurse', 'other')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create MILESTONES Master Table
CREATE TABLE public.milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  min_age_months INT NOT NULL,
  max_age_months INT NOT NULL,
  category VARCHAR(30) CHECK (category IN ('gross_motor', 'fine_motor', 'speech_language', 'social_emotional')),
  question_text TEXT NOT NULL
);

-- 5. Create CHILD_MILESTONE_LOGS Table
CREATE TABLE public.child_milestone_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  milestone_id UUID NOT NULL REFERENCES public.milestones(id) ON DELETE CASCADE,
  is_achieved BOOLEAN NOT NULL DEFAULT FALSE,
  checked_at DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 6. Create IMMUNIZATIONS Master Table
CREATE TABLE public.immunizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vaccine_name TEXT NOT NULL,
  recommended_age_months INT NOT NULL
);

-- 7. Create CHILD_IMMUNIZATION_LOGS Table (Imunisasi & Pencatatan Nakes)
CREATE TABLE public.child_immunization_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
  immunization_id UUID NOT NULL REFERENCES public.immunizations(id) ON DELETE CASCADE,
  administered_date DATE NOT NULL,
  batch_number TEXT,
  healthcare_location TEXT,
  administrator_name TEXT,
  administrator_type VARCHAR(20) CHECK (administrator_type IN ('pediatrician', 'midwife', 'general_practitioner', 'nurse', 'other'))
);