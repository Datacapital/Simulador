-- =====================================================
-- Supabase Schema for Papeles Comerciales Dashboard
-- Execute this SQL in your Supabase SQL Editor
-- =====================================================

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- =====================================================
-- TABLE: empresas
-- Stores company information for each user
-- =====================================================
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    UNIQUE(nombre, usuario_id)
);

-- Enable RLS on empresas
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own empresas
CREATE POLICY "Users can view own empresas" ON public.empresas
    FOR SELECT USING (auth.uid() = usuario_id);

-- Policy: Users can insert their own empresas
CREATE POLICY "Users can insert own empresas" ON public.empresas
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

-- Policy: Users can update their own empresas
CREATE POLICY "Users can update own empresas" ON public.empresas
    FOR UPDATE USING (auth.uid() = usuario_id);

-- Policy: Users can delete their own empresas
CREATE POLICY "Users can delete own empresas" ON public.empresas
    FOR DELETE USING (auth.uid() = usuario_id);

-- Index for faster queries
CREATE INDEX idx_empresas_usuario_id ON public.empresas(usuario_id);
CREATE INDEX idx_empresas_fecha_creacion ON public.empresas(fecha_creacion DESC);

-- =====================================================
-- TABLE: recaudos
-- Stores document/requirement status for each company
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

-- Enable RLS on recaudos
ALTER TABLE public.recaudos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see recaudos of their own empresas
CREATE POLICY "Users can view own recaudos" ON public.recaudos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

-- Policy: Users can insert recaudos for their own empresas
CREATE POLICY "Users can insert own recaudos" ON public.recaudos
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

-- Policy: Users can update recaudos of their own empresas
CREATE POLICY "Users can update own recaudos" ON public.recaudos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

-- Policy: Users can delete recaudos of their own empresas
CREATE POLICY "Users can delete own recaudos" ON public.recaudos
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.empresas
            WHERE empresas.id = recaudos.empresa_id
            AND empresas.usuario_id = auth.uid()
        )
    );

-- Indexes for faster queries
CREATE INDEX idx_recaudos_empresa_id ON public.recaudos(empresa_id);
CREATE INDEX idx_recaudos_nombre ON public.recaudos(nombre_recaudo);
CREATE INDEX idx_recaudos_estado ON public.recaudos(estado_booleano);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_recaudos_updated_at
    BEFORE UPDATE ON public.recaudos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STORAGE: Create bucket for document files
-- Run this in Supabase Dashboard > Storage > Create Bucket
-- =====================================================
-- Bucket name: documentos
-- Public: false (private bucket)
-- File size limit: 50MB
-- Allowed MIME types: application/pdf, image/*

-- Storage Policies (run in SQL Editor after creating bucket):

-- Policy: Allow authenticated users to upload files to their folder
-- INSERT INTO storage.policies (name, bucket_id, definition)
-- VALUES (
--     'Users can upload documents',
--     'documentos',
--     'bucket_id = ''documentos'' AND auth.role() = ''authenticated'' AND (storage.foldername(name))[1] = auth.uid()::text'
-- );

-- =====================================================
-- SAMPLE DATA FOR TESTING (Optional)
-- =====================================================

-- To create a test user, use Supabase Auth in the Dashboard
-- Then you can insert test data:

-- INSERT INTO public.empresas (nombre, usuario_id)
-- VALUES ('Empresa Demo', 'your-user-uuid-here');

-- INSERT INTO public.recaudos (empresa_id, nombre_recaudo, estado_booleano, metadata_json)
-- VALUES
--     ('empresa-uuid', 'legal-ubicaciones', true, '{}'),
--     ('empresa-uuid', 'legal-permisos', false, '{}'),
--     ('empresa-uuid', 'legal-empresa-matrix', true, '{"aplica": true}'),
--     ('empresa-uuid', 'legal-actas', true, '{"items": [{"date": "2024-01-15", "fileName": "acta1.pdf", "filePath": "user-id/actas/acta1.pdf"}]}');

-- =====================================================
-- VIEWS (Optional - for reporting)
-- =====================================================

-- View: Progress summary per empresa
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

-- Grant access to the view
GRANT SELECT ON public.empresa_progress TO authenticated;

-- =====================================================
-- REALTIME: Enable realtime for tables
-- =====================================================

-- Enable realtime for recaudos table
ALTER PUBLICATION supabase_realtime ADD TABLE public.recaudos;

-- Enable realtime for empresas table
ALTER PUBLICATION supabase_realtime ADD TABLE public.empresas;

-- =====================================================
-- STORAGE BUCKET SETUP (Manual steps in Supabase Dashboard)
-- =====================================================
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create a new bucket called "documentos"
-- 3. Set it as private (not public)
-- 4. Add the following RLS policies:

-- For uploads (INSERT):
-- ((bucket_id = 'documentos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))

-- For downloads (SELECT):
-- ((bucket_id = 'documentos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))

-- For deletes (DELETE):
-- ((bucket_id = 'documentos'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))
