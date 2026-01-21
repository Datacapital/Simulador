# 💼 Simulador de Presupuesto de Emisión - Per Capital

Sistema web para generar presupuestos detallados de emisión de deuda en Venezuela, con cálculo automático de costos regulatorios, comisiones y proyección de intereses.

## 🚀 Características

- ✅ **Cálculo automático** de tasas SUNAVAL, calificación de riesgo, y otros costos del mercado
- 📊 **PDF profesional** en una sola página con logo personalizable
- 💰 **Distinción PYME/Corporativo** con tarifas diferenciadas
- 🎯 **Comisiones configurables** de estructuración y colocación
- 📈 **Proyección de intereses** según plazo y tasa

## 📋 Uso

### 1. Abrir el simulador
Simplemente abre el archivo `presupuesto.html` en tu navegador web.

### 2. Cargar el logo (IMPORTANTE)

Para que el logo aparezca en el PDF, sigue estos pasos:

#### Opción A: Descargar desde Google Drive y cargar
1. **Descarga el logo** desde: [Logo Per Capital](https://drive.google.com/file/d/15pmFQwoVnFkXP_0VPFiG812nxr80yiIl/view?usp=sharing)
   - Haz clic en el enlace
   - Click en "Descargar" o el ícono de descarga (⬇️)
   - Guarda el archivo en tu computadora

2. **Carga el logo en el simulador**:
   - En la sección amarilla "⚙️ Cargar Logo para PDF"
   - Haz clic en "Elegir archivo" o "Choose file"
   - Selecciona el logo descargado
   - Verás el mensaje "Logo cargado exitosamente"

#### Opción B: Usar el logo directamente desde la web
Si prefieres, puedes modificar el código para que el logo se cargue automáticamente:

1. Descarga el logo desde Google Drive
2. Convierte la imagen a base64 usando una herramienta como:
   - https://base64.guru/converter/encode/image
   - https://www.base64-image.de/
3. Copia el código base64 generado
4. En el archivo `presupuesto.html`, busca la línea:
   ```javascript
   let LOGO_BASE64 = "";
   ```
5. Pégalo entre las comillas:
   ```javascript
   let LOGO_BASE64 = "data:image/png;base64,iVBORw0KGg...";
   ```

### 3. Completar el formulario

1. **Datos del Cliente**:
   - Nombre del emisor
   - Tipo de emisor (PYME o Corporativo)

2. **Características de la Emisión**:
   - Monto a emitir (USD)
   - Plazo (días)
   - Tasa de interés (% anual)
   - Frecuencia de pago de intereses
   - Amortización de capital

3. **Comisiones Per Capital**:
   - Estructuración Legal (%)
   - Colocación ≤ $1M (%)
   - Colocación > $1M (%)

### 4. Generar presupuesto

- Haz clic en **"GENERAR PRESUPUESTO"**
- Revisa el desglose en pantalla
- Haz clic en **"GENERAR PDF PARA CLIENTE"** para descargar

## 💡 Detalles Técnicos

### Costos Calculados Automáticamente

| Concepto | Tarifa |
|----------|--------|
| Registro Nacional SUNAVAL | 1% (PYME) / 2% (Corporativo) |
| Contribución Especial Anual | 0.50% del monto |
| Calificación de Riesgo | $800 (<$50k) / $1,500 (PYME) / $3,000 (Corp) |
| Representación de Tenedores | 0.25% del monto |
| Publicación de Aviso | $25 (tarifa plana) |
| Bolsa de Valores (BVCC) | 0.50% del monto |
| Inscripción ISIN | $38-$160 según plazo |
| Custodia CVV | 0.03% mensual |
| IVA sobre CVV | 16% |

### Características del PDF

- ✅ **Una sola página** A4
- ✅ Logo en esquina superior izquierda (40mm x 12mm)
- ✅ Tablas compactas y profesionales
- ✅ Cálculo del costo total de emisión
- ✅ Fecha y lugar de emisión

## 🔧 Tecnologías

- **HTML5** + **CSS3**: Interfaz moderna y responsiva
- **JavaScript**: Lógica de cálculo
- **jsPDF**: Generación de PDF
- **jsPDF-AutoTable**: Tablas profesionales en PDF
- **Google Fonts**: Plus Jakarta Sans

## 📝 Notas

- El presupuesto es **estimativo**
- Los costos regulatorios están basados en tarifas vigentes en Venezuela
- Las comisiones Per Capital son configurables según el cliente
- El PDF está optimizado para impresión A4

## 📄 Licencia

Per Capital - Estructuración de Instrumentos de Deuda

---

**Desarrollado para Per Capital** | Caracas, Venezuela 🇻🇪
