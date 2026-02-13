-- =====================================================
-- MIGRACION: Eliminar dependencia de auth.users
-- Ejecutar en Supabase SQL Editor (una sola vez)
-- =====================================================

-- 1. Eliminar politicas RLS existentes de empresas
DROP POLICY IF EXISTS "Users can view own empresas" ON public.empresas;
DROP POLICY IF EXISTS "Users can insert own empresas" ON public.empresas;
DROP POLICY IF EXISTS "Users can update own empresas" ON public.empresas;
DROP POLICY IF EXISTS "Users can delete own empresas" ON public.empresas;
DROP POLICY IF EXISTS "Allow all for empresas" ON public.empresas;

-- 2. Eliminar FK a auth.users y cambiar tipo a TEXT
ALTER TABLE public.empresas DROP CONSTRAINT IF EXISTS empresas_usuario_id_fkey;
ALTER TABLE public.empresas ALTER COLUMN usuario_id TYPE TEXT;

-- 3. Crear politicas abiertas (la app maneja auth via password)
CREATE POLICY "Allow all for empresas" ON public.empresas
    FOR ALL USING (true) WITH CHECK (true);

-- 4. Eliminar politicas RLS existentes de recaudos
DROP POLICY IF EXISTS "Users can view own recaudos" ON public.recaudos;
DROP POLICY IF EXISTS "Users can insert own recaudos" ON public.recaudos;
DROP POLICY IF EXISTS "Users can update own recaudos" ON public.recaudos;
DROP POLICY IF EXISTS "Users can delete own recaudos" ON public.recaudos;
DROP POLICY IF EXISTS "Allow all for recaudos" ON public.recaudos;

-- 5. Crear politicas abiertas para recaudos
CREATE POLICY "Allow all for recaudos" ON public.recaudos
    FOR ALL USING (true) WITH CHECK (true);

-- 6. Actualizar vista de progreso
CREATE OR REPLACE VIEW public.empresa_progress AS
SELECT
    e.id as empresa_id,
    e.nombre as empresa_nombre,
    e.usuario_id,
    COUNT(r.id) as total_recaudos,
    COUNT(CASE WHEN r.estado_booleano = true THEN 1 END) as completed_recaudos,
    CASE
        WHEN COUNT(r.id) > 0
        THEN ROUND((COUNT(CASE WHEN r.estado_booleano = true THEN 1 END)::numeric / COUNT(r.id)::numeric) * 100, 2)
        ELSE 0
    END as progress_percentage
FROM public.empresas e
LEFT JOIN public.recaudos r ON e.id = r.empresa_id
GROUP BY e.id, e.nombre, e.usuario_id;

GRANT SELECT ON public.empresa_progress TO anon, authenticated;
