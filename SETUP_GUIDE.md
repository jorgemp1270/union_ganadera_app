# Guía de Configuración Rápida

## Configuración Inicial

### 1. Instalar Dependencias
```bash
cd union_ganadera_app
flutter pub get
```

### 2. Configurar la URL del Backend

Edita el archivo `lib/services/api_client.dart` y cambia la URL base:

```dart
static const String baseUrl = 'http://localhost:8000';  // Para desarrollo local
// O
static const String baseUrl = 'https://tu-servidor.com';  // Para producción
```

### 3. Configurar Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`)

Añade estos permisos antes de `</manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.NFC" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

#### iOS (`ios/Runner/Info.plist`)

Añade estas descripciones antes de `</dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos de documentos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para registrar coordenadas de predios</string>
<key>NFCReaderUsageDescription</key>
<string>Necesitamos acceso a NFC para leer aretes RFID</string>
```

### 4. Ejecutar la Aplicación

#### En Emulador/Simulador
```bash
flutter run
```

#### En Dispositivo Físico
```bash
# Android
flutter run

# iOS
flutter run -d "iPhone de [Tu Nombre]"
```

#### Generar APK (Android)
```bash
flutter build apk --release
```

#### Generar IPA (iOS)
```bash
flutter build ios --release
```

## Características por Pantalla

### Splash Screen
- Se muestra durante 2 segundos
- Verifica si hay sesión activa
- Redirige a Login o Home según corresponda

### Login
- CURP (18 caracteres)
- Contraseña
- Validación de campos

### Registro (Signup)
- **IMPORTANTE**: Banner que advierte que los datos deben coincidir con el INE
- Campos de datos personales
- Validación automática de CURP
- Captura de fotos:
  - INE (identificación)
  - Comprobante de domicilio
- Sube documentos automáticamente después del registro

### Home (Navegación Principal)
Tres pestañas:
1. **Ganado** - Lista de bovinos
2. **Predios** - Propiedades registradas
3. **Perfil** - Información del usuario

### Lista de Ganado
- Búsqueda por arete o raza
- Card con información resumida
- Botón flotante para registrar nuevo ganado

### Registrar Ganado
- Campos opcionales
- **Escaneo de código de barras** para arete
- **Escaneo NFC** para arete RFID (si está disponible)
- Datos: raza, sexo, fecha nacimiento, pesos, propósito

### Detalle de Ganado
- Información completa
- Historial de eventos
- Botón para registrar nuevo evento

### Predios
- Lista de predios
- Botón para registrar nuevo predio
- Diálogo modal para registro que incluye:
  - Clave catastral
  - Superficie
  - **Botón para obtener ubicación GPS automáticamente**
  - Captura de documento comprobatorio

### Perfil
- Información del usuario
- **Estado de documentos** (Autorizado/Pendiente)
- Indicadores visuales por tipo de documento
- Botón de cerrar sesión

### Registrar Evento
- Puede aplicarse a uno o varios bovinos
- Tipos: Peso, Dieta
- Campos específicos según el tipo
- Observaciones opcionales

## Flujo de Trabajo Típico

1. **Primera vez**: Registro → Login → Ver documentos pendientes
2. **Registrar Ganado**: Home → Ganado → + → Escanear/Llenar → Guardar
3. **Registrar Predio**: Home → Predios → + → Obtener GPS → Foto → Guardar
4. **Evento de Peso**: Home → Ganado → Seleccionar → Nuevo Evento → Peso → Guardar

## Solución de Problemas

### Error de conexión
- Verifica que el backend esté corriendo
- Verifica la URL en `api_client.dart`
- En Android, asegúrate de tener permiso de INTERNET

### Permisos no funcionan
- Revisa AndroidManifest.xml / Info.plist
- Desinstala y vuelve a instalar la app
- En Android Studio: Build → Clean Project

### NFC no disponible
- Solo funciona en dispositivos con NFC
- La app detecta automáticamente y muestra/oculta el botón

### GPS no funciona
- Activa ubicación en el dispositivo
- Acepta permisos cuando se soliciten
- En emulador, simula ubicación

## Notas de Desarrollo

- El CURP se valida usando el algoritmo traducido de Java en `curp_validator.dart`
- Los tokens se guardan de forma segura con `flutter_secure_storage`
- Las imágenes se toman con la cámara por defecto (puedes cambiar a galería)
- Los documentos se suben con multipart/form-data

## Variables de Entorno Recomendadas

Para producción, considera usar:
- `flutter_dotenv` para variables de entorno
- Diferentes URLs para dev/staging/prod
- Configuración de sentry para errores
