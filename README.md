# Unión Ganadera App

Aplicación móvil desarrollada en Flutter para la gestión integral de ganado, predios y eventos ganaderos de la Unión Ganadera.

## 📋 Descripción

Esta aplicación permite a los ganaderos registrar y gestionar su ganado, predios y eventos relacionados con la actividad ganadera. Incluye funcionalidades avanzadas como lectura de códigos de barras, NFC, captura de ubicación GPS y carga de documentos.

## ✨ Características

- **Autenticación de Usuarios**
  - Registro con validación de INE y CURP
  - Inicio de sesión con JWT
  - Guardado de credenciales
  - Configuración de API personalizable

- **Gestión de Ganado**
  - Registro de ganado con código de barras o NFC
  - Consulta de detalles del ganado
  - Historial de eventos por tipo

- **Gestión de Predios**
  - Registro de predios con captura de ubicación GPS
  - Carga de documentos (comprobante de propiedad, uso de suelo)
  - Lista y detalles de predios registrados

- **Registro de Eventos**
  - 9 tipos de eventos: Peso, Dieta, Vacunación, Desparasitación, Laboratorio, Compra/Venta, Traslado, Enfermedad, Tratamiento
  - Registro individual o múltiple
  - Historial completo de eventos

- **Perfil de Usuario**
  - Visualización de datos personales
  - Carga de documentos (INE frontal/trasera, comprobante de domicilio)
  - Configuración de la aplicación

## 🛠️ Requisitos Previos

- Flutter SDK 3.7.2 o superior
- Dart 2.19.0 o superior
- Android Studio / VS Code con extensiones de Flutter
- Dispositivo Android/iOS o emulador configurado
- API Backend en ejecución (ver [API_DOCUMENTATION.md](API_DOCUMENTATION.md))

## 📦 Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/union_ganadera_app.git
   cd union_ganadera_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Verificar la instalación de Flutter**
   ```bash
   flutter doctor
   ```
   Asegúrate de que todos los componentes necesarios estén instalados correctamente.

4. **Configurar el emulador o dispositivo**
   - Para Android: Configura un dispositivo virtual en Android Studio
   - Para iOS: Abre el simulador de iOS (solo macOS)
   - Para dispositivo físico: Habilita el modo desarrollador y la depuración USB

## ⚙️ Configuración

### Configuración de la API

La aplicación permite configurar la dirección del servidor API directamente desde la interfaz:

1. En la pantalla de inicio de sesión, presiona el ícono de engranaje (⚙️) en la esquina superior derecha
2. Ingresa la dirección IP y puerto del servidor API
3. Guarda los cambios

**Configuración por defecto:**
- IP: `10.0.2.2` (localhost del emulador Android)
- Puerto: `8000`

Para cambiar la configuración por defecto, modifica [lib/services/api_client.dart](lib/services/api_client.dart):

```dart
static const String defaultBaseUrl = 'http://TU_IP:TU_PUERTO';
```

### Permisos

La aplicación requiere los siguientes permisos:

**Android** (configurados en `android/app/src/main/AndroidManifest.xml`):
- INTERNET
- CAMERA (escaneo de códigos de barras)
- ACCESS_FINE_LOCATION (GPS para predios)
- ACCESS_COARSE_LOCATION
- NFC (lectura de tags NFC)
- READ_EXTERNAL_STORAGE (carga de documentos)
- WRITE_EXTERNAL_STORAGE

**iOS** (configurados en `ios/Runner/Info.plist`):
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSPhotoLibraryUsageDescription
- NFCReaderUsageDescription

## 🚀 Ejecución

### Modo Debug
```bash
flutter run
```

### Modo Release
```bash
flutter run --release
```

### Ejecutar en un dispositivo específico
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run -d <device_id>
```

## 📱 Uso de la Aplicación

1. **Primer Uso**
   - Configura la dirección del servidor API si es necesario
   - Regístrate con tus datos personales
   - Completa la validación de INE y CURP

2. **Gestión de Ganado**
   - Desde el menú principal, selecciona "Ganado"
   - Registra nuevo ganado escaneando código de barras o tag NFC
   - Consulta el historial de eventos por animal

3. **Gestión de Predios**
   - Accede a "Predios" desde el menú
   - Registra un nuevo predio con ubicación GPS
   - Sube los documentos requeridos

4. **Registro de Eventos**
   - Selecciona "Eventos" en el menú
   - Elige el tipo de evento a registrar
   - Completa el formulario y envía

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── models/                      # Modelos de datos
│   ├── user.dart
│   ├── ganado.dart
│   ├── predio.dart
│   └── evento.dart
├── services/                    # Servicios de API y lógica de negocio
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── ganado_service.dart
│   ├── predio_service.dart
│   ├── evento_service.dart
│   └── file_service.dart
├── screens/                     # Pantallas de la aplicación
│   ├── auth/
│   │   ├── auth_screen.dart    # Pantalla de autenticación con tabs
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── cattle/
│   │   ├── ganado_list_screen.dart
│   │   ├── register_ganado_screen.dart
│   │   └── cattle_detail_screen.dart
│   ├── predios/
│   │   ├── predio_list_screen.dart
│   │   ├── register_predio_screen.dart
│   │   └── predio_detail_screen.dart
│   ├── events/
│   │   └── register_event_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── settings/
│       └── api_settings_screen.dart
├── utils/                       # Utilidades
│   └── curp_validator.dart     # Validador de CURP (RFC)
└── widgets/                     # Widgets reutilizables
```

## 🔧 Tecnologías Utilizadas

- **Framework:** Flutter 3.7.2+
- **Lenguaje:** Dart
- **HTTP Client:** dio (^5.4.0)
- **Almacenamiento Seguro:** flutter_secure_storage (^9.0.0)
- **Gestión de Estado:** provider (^6.1.1)
- **Imágenes:** image_picker (^1.0.7), file_picker (^6.1.1)
- **Ubicación:** geolocator (^11.0.0), permission_handler (^11.2.0)
- **Escaneo:** mobile_scanner (^3.5.5), nfc_manager (^3.3.0)
- **Internacionalización:** intl (^0.19.0)

## 📖 Documentación Adicional

- [API Documentation](API_DOCUMENTATION.md) - Documentación completa de la API REST

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor, sigue estos pasos:

1. Fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit de tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado y propiedad de la Unión Ganadera.

## 👥 Autores

- Equipo de Desarrollo de la Unión Ganadera

## 📞 Soporte

Para soporte técnico o consultas, contacta a: [soporte@unionganadera.com](mailto:soporte@unionganadera.com)
