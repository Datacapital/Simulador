# Guia de Configuracion - Dashboard Papeles Comerciales Per Capital

## 1. SUPABASE - Configuracion del Proyecto

### Crear Proyecto en Supabase
- **Nombre del proyecto:** `percapital-emisiones`
- **Region:** East US (Virginia) o la mas cercana
- **Database Password:** (guarda esto de forma segura)

### Credenciales que necesitas copiar
Despues de crear el proyecto, ve a **Settings > API** y copia:
- **Project URL:** algo como `https://xyzabc123.supabase.co`
- **anon/public key:** la clave publica (empieza con `eyJ...`)

### Configurar Base de Datos
1. Ve a **SQL Editor** en el panel de Supabase
2. Copia y pega TODO el contenido de `supabase-schema.sql`
3. Ejecuta el script

Esto creara:
- Tabla `empresas` (id, nombre, fecha_creacion, usuario_id)
- Tabla `recaudos` (id, empresa_id, nombre_recaudo, estado_booleano, metadata_json)
- Politicas de seguridad RLS
- Indices para rendimiento
- Vista `empresa_progress` para reportes
- Triggers para timestamps
- Real-time habilitado en ambas tablas

### Configurar Autenticacion
1. Ve a **Authentication > Users**
2. Click **Add User > Create New User**
3. Datos del usuario:
   - **Email:** `javier@percapital.com`
   - **Password:** (el que elijas)
   - **Auto Confirm User:** Si (activar)
   - **User Metadata (JSON):** `{"full_name": "Javier Melendez", "department": "Tesoreria"}`

### Configurar Storage
1. Ve a **Storage** en el panel
2. Click **New Bucket**
   - **Nombre del bucket:** `documentos`
   - **Public bucket:** No (desactivado)
   - **File size limit:** 50MB
   - **Allowed MIME types:** `application/pdf, image/*, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document`
3. Ve a **Policies** del bucket `documentos` y crea estas 3 politicas:

**Politica INSERT (subir archivos):**
- Name: `Users can upload`
- Target roles: `authenticated`
- Policy: `(storage.foldername(name))[1] = auth.uid()::text`

**Politica SELECT (descargar archivos):**
- Name: `Users can download own files`
- Target roles: `authenticated`
- Policy: `(storage.foldername(name))[1] = auth.uid()::text`

**Politica DELETE (borrar archivos):**
- Name: `Users can delete own files`
- Target roles: `authenticated`
- Policy: `(storage.foldername(name))[1] = auth.uid()::text`

### Habilitar Realtime
1. Ve a **Database > Replication**
2. Activa el source `supabase_realtime`
3. Asegurate de que las tablas `empresas` y `recaudos` estan en la lista

---

## 2. ACTUALIZAR CREDENCIALES EN EL CODIGO

Abre `dashboard.html` y busca estas dos lineas (cerca de la linea 270):

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Reemplaza con tus valores reales:
```javascript
const SUPABASE_URL = 'https://tu-proyecto.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...tu-clave-aqui';
```

Tambien actualiza `supabase-config.js` con los mismos valores.

---

## 3. RENDER - Despliegue del Sitio

### Crear Static Site en Render
1. Ve a https://dashboard.render.com
2. Click **New > Static Site**
3. Configuracion:
   - **Name:** `percapital-dashboard`
   - **Repository:** conecta tu repo de GitHub `Datacapital/Simulador`
   - **Branch:** `claude/build-emissions-dashboard-3lpse` (o `main` cuando hagas merge)
   - **Build Command:** (dejar vacio - es HTML estatico)
   - **Publish Directory:** `.` (punto, la raiz del repo)

### URLs resultantes en Render
- **Dashboard:** `https://percapital-dashboard.onrender.com/dashboard.html`
- **Simulador:** `https://percapital-dashboard.onrender.com/index.html`

### Variables de Entorno en Render (Opcional)
Si prefieres no exponer las credenciales en el codigo, puedes usar
un build script que las inyecte. Para un sitio estatico simple,
las credenciales del client-side (anon key) son seguras de exponer
ya que Supabase usa RLS para proteger los datos.

---

## 4. ESTRUCTURA DE ARCHIVOS

```
Simulador/
  index.html              -> Simulador de emisiones (existente)
  dashboard.html           -> Dashboard de control con Supabase
  supabase-config.js       -> Configuracion reutilizable de Supabase
  supabase-schema.sql      -> SQL para crear tablas en Supabase
  SETUP-GUIDE.md           -> Esta guia
```

---

## 5. FUNCIONALIDADES IMPLEMENTADAS

| Funcionalidad | Estado |
|---|---|
| Login con Supabase Auth | Implementado |
| CRUD de empresas en DB | Implementado |
| Checkboxes sincronizados en tiempo real | Implementado |
| Subida de archivos a Supabase Storage | Implementado |
| Barra de progreso calculada desde DB | Implementado |
| Switch Aplica/No Aplica con N/A | Implementado |
| Listas dinamicas (Licencias, RRHH) con borrado en DB | Implementado |
| Actas Constitutivas con fecha y archivo | Implementado |
| Aumentos de Capital con fecha y archivo | Implementado |
| Marcas y RRSS con documento adjunto | Implementado |
| Validacion Empresa Matrix vs Acta Constitutiva | Implementado |
| Indicador de sincronizacion visual | Implementado |

---

## 6. FLUJO DE DATOS

```
Usuario marca checkbox
    -> change event
    -> queueSave() (cola serializada)
    -> Supabase INSERT/UPDATE en tabla recaudos
    -> Real-time broadcast
    -> Otros clientes reciben el cambio
    -> updateProgress() recalcula porcentaje
```

```
Usuario sube archivo (Acta/Aumento/Marca)
    -> uploadFileToStorage() -> Supabase Storage bucket "documentos"
    -> Ruta del archivo se guarda en metadata_json del recaudo
    -> addListItem() -> Supabase UPDATE en tabla recaudos
```

```
Aplica/No Aplica
    -> Click toggle -> cicla: Aplica -> No Aplica -> Reset
    -> Si "No Aplica": metadata_json.aplica = false
    -> El recaudo NO cuenta en el calculo de progreso
    -> estado_booleano se mantiene pero es ignorado en %
```
