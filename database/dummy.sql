-- 1. Insert Master Data Imunisasi Wajib (Sesuai Jadwal Kemenkes/IDAI)
INSERT INTO public.immunizations (vaccine_name, recommended_age_months) VALUES
('Hepatitis B (HB-0)', 0),
('BCG', 1),
('Polio Tetes 1 (OPV 1)', 1),
('DPT-HB-Hib 1', 2),
('Polio Tetes 2 (OPV 2)', 2),
('PCV 1', 2),
('Rotavirus 1', 2),
('DPT-HB-Hib 2', 3),
('Polio Tetes 3 (OPV 3)', 3),
('PCV 2', 3),
('Rotavirus 2', 3),
('DPT-HB-Hib 3', 4),
('Polio Tetes 4 (OPV 4)', 4),
('Polio Suntik 1 (IPV 1)', 4),
('Rotavirus 3', 4),
('Campak Rubella (MR 1)', 9),
('Polio Suntik 2 (IPV 2)', 9),
('PCV 3', 12),
('JE (Javanese Encephalitis)', 12),
('DPT-HB-Hib Lanjutan (Booster)', 18),
('Campak Rubella Lanjutan (MR 2)', 18);

-- 2. Insert Master Data Milestones (Ceklis Perkembangan 0-3 Bulan Pertama)
INSERT INTO public.milestones (min_age_months, max_age_months, category, question_text) VALUES
-- Motorik Kasar (0-3 Bulan)
(0, 3, 'gross_motor', 'Apakah bayi bisa mengangkat kepala sebentar saat ditengkurepkan?'),
(0, 3, 'gross_motor', 'Apakah gerakan tangan dan kaki bayi terlihat aktif dan seimbang di kedua sisi?'),

-- Motorik Halus (0-3 Bulan)
(0, 3, 'fine_motor', 'Apakah jemari bayi bisa menggenggam jari atau benda kecil yang diletakkan di telapak tangannya?'),
(0, 3, 'fine_motor', 'Apakah bayi sering menatap jarinya sendiri atau mengarahkan tangan ke mulut?'),

-- Bicara & Bahasa (0-3 Bulan)
(0, 3, 'speech_language', 'Apakah bayi bereaksi (terkejut/menoleh) saat mendengar suara keras atau panggilan?'),
(0, 3, 'speech_language', 'Apakah bayi mulai mengeluarkan suara tenggorokan gembira ("cooing" seperti "ooh", "aah")?'),

-- Sosialisasi & Emosional (0-3 Bulan)
(0, 3, 'social_emotional', 'Apakah bayi bisa tersenyum spontan saat diajak bicara atau ditatap?'),
(0, 3, 'social_emotional', 'Apakah bayi mulai menatap wajah ibu/pengasuh dengan fokus saat menyusu?');