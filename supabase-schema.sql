-- =====================================================
-- Supabase Schema for Papeles Comerciales Dashboard
-- Execute this SQL in your Supabase SQL Editor
-- Safe to re-run: uses IF NOT EXISTS and DROP IF EXISTS
-- =====================================================

-- =====================================================
-- TABLE: empresas
-- =====================================================
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    UNIQUE(nombre, usuario_id)
);

ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own empresas" ON public.empresas;
CREATE POLICY "Users can view own empresas" ON public.empresas
    FOR SELECT USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Users can insert own empresas" ON public.empresas;
CREATE POLICY "Users can insert own empresas" ON public.empresas
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Users can update own empresas" ON public.empresas;
CREATE POLICY "Users can update own empresas" ON public.empresas
    FOR UPDATE USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Users can delete own empresas" ON public.empresas;
CREATE POLICY "Users can delete own empresas" ON public.empresas
    FOR DELETE USING (auth.uid() = usuario_id);

CREATE INDEX IF NOT EXISTS idx_empresas_usuario_id ON public.empresas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_empresas_fecha_creacion ON public.empresas(fecha_creacion DESC);

-- =====================================================
-- TABLE: recaudos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.recaudos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nombre_recaudo VARCHAR(255) NOT NULL,
    estado_booleano BOOLEAN DEFAULT FALSE,
    metadata_json JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(empresa_id, nombre_recaudo)
);

ALTER TABLE public.recaudos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own recaudos" ON public.recaudos;
CREATE POLICY "Users can view own recaudos" ON public.recaudos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert own recaudos" ON public.recaudos;
CREATE POLICY "Users can insert own recaudos" ON public.recaudos
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update own recaudos" ON public.recaudos;
CREATE POLICY "Users can update own recaudos" ON public.recaudos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own recaudos" ON public.recaudos;
CREATE POLICY "Users can delete own recaudos" ON public.recaudos
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

CREATE INDEX IF NOT EXISTS idx_recaudos_empresa_id ON public.recaudos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_recaudos_nombre ON public.recaudos(nombre_recaudo);
CREATE INDEX IF NOT EXISTS idx_recaudos_estado ON public.recaudos(estado_booleano);

-- Trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_recaudos_updated_at ON public.recaudos;
CREATE TRIGGER update_recaudos_updated_at
    BEFORE UPDATE ON public.recaudos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VIEW: Progress per empresa
-- =====================================================
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

GRANT SELECT ON public.empresa_progress TO authenticated;

-- =====================================================
-- REALTIME
-- =====================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.recaudos;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.empresas;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;
