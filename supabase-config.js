// Supabase Configuration
// Replace these values with your actual Supabase project credentials
const SUPABASE_URL = 'https://hyapzawkrzldgadzxnlx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5YXB6YXdrcnpsZGdhZHp4bmx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MTU1NjIsImV4cCI6MjA4NTE5MTU2Mn0.9ynfmd5m4LdeUNC1jxl6l3IkW_dETORrRlufSj9PlH8';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Export for use in other files
window.supabaseClient = supabase;

// Helper functions for common Supabase operations
const SupabaseHelper = {
    // Authentication
    async signIn(email, password) {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });
        if (error) throw error;
        return data;
    },

    async signOut() {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
    },

    async getCurrentUser() {
        const { data: { user } } = await supabase.auth.getUser();
        return user;
    },

    onAuthStateChange(callback) {
        return supabase.auth.onAuthStateChange(callback);
    },

    // Empresas CRUD
    async getEmpresas(userId) {
        const { data, error } = await supabase
            .from('empresas')
            .select('*')
            .eq('usuario_id', userId)
            .order('fecha_creacion', { ascending: false });
        if (error) throw error;
        return data;
    },

    async createEmpresa(nombre, userId) {
        const { data, error } = await supabase
            .from('empresas')
            .insert([{ nombre, usuario_id: userId }])
            .select()
            .single();
        if (error) throw error;
        return data;
    },

    async deleteEmpresa(empresaId) {
        // First delete all related recaudos
        await supabase
            .from('recaudos')
            .delete()
            .eq('empresa_id', empresaId);

        // Then delete the empresa
        const { error } = await supabase
            .from('empresas')
            .delete()
            .eq('id', empresaId);
        if (error) throw error;
    },

    // Recaudos CRUD
    async getRecaudos(empresaId) {
        const { data, error } = await supabase
            .from('recaudos')
            .select('*')
            .eq('empresa_id', empresaId);
        if (error) throw error;
        return data;
    },

    async upsertRecaudo(empresaId, nombreRecaudo, estadoBooleano, metadataJson = null) {
        // Check if recaudo exists
        const { data: existing } = await supabase
            .from('recaudos')
            .select('id')
            .eq('empresa_id', empresaId)
            .eq('nombre_recaudo', nombreRecaudo)
            .single();

        if (existing) {
            // Update
            const { data, error } = await supabase
                .from('recaudos')
                .update({
                    estado_booleano: estadoBooleano,
                    metadata_json: metadataJson
                })
                .eq('id', existing.id)
                .select()
                .single();
            if (error) throw error;
            return data;
        } else {
            // Insert
            const { data, error } = await supabase
                .from('recaudos')
                .insert([{
                    empresa_id: empresaId,
                    nombre_recaudo: nombreRecaudo,
                    estado_booleano: estadoBooleano,
                    metadata_json: metadataJson
                }])
                .select()
                .single();
            if (error) throw error;
            return data;
        }
    },

    async deleteRecaudo(recaudoId) {
        const { error } = await supabase
            .from('recaudos')
            .delete()
            .eq('id', recaudoId);
        if (error) throw error;
    },

    async deleteRecaudoByName(empresaId, nombreRecaudo) {
        const { error } = await supabase
            .from('recaudos')
            .delete()
            .eq('empresa_id', empresaId)
            .eq('nombre_recaudo', nombreRecaudo);
        if (error) throw error;
    },

    // Storage operations
    async uploadFile(bucket, path, file) {
        const { data, error } = await supabase.storage
            .from(bucket)
            .upload(path, file, {
                cacheControl: '3600',
                upsert: true
            });
        if (error) throw error;
        return data;
    },

    async deleteFile(bucket, path) {
        const { error } = await supabase.storage
            .from(bucket)
            .remove([path]);
        if (error) throw error;
    },

    getPublicUrl(bucket, path) {
        const { data } = supabase.storage
            .from(bucket)
            .getPublicUrl(path);
        return data.publicUrl;
    },

    // Real-time subscriptions
    subscribeToRecaudos(empresaId, callback) {
        return supabase
            .channel(`recaudos-${empresaId}`)
            .on('postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'recaudos',
                    filter: `empresa_id=eq.${empresaId}`
                },
                callback
            )
            .subscribe();
    },

    subscribeToEmpresas(userId, callback) {
        return supabase
            .channel(`empresas-${userId}`)
            .on('postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'empresas',
                    filter: `usuario_id=eq.${userId}`
                },
                callback
            )
            .subscribe();
    },

    unsubscribe(channel) {
        supabase.removeChannel(channel);
    }
};

window.SupabaseHelper = SupabaseHelper;
