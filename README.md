# Unión Ganadera App

Aplicación móvil desarrollada en Flutter para la gestión integral de ganado, predios y eventos ganaderos de la Unión Ganadera.

## 📋 Descripción

Esta aplicación permite a los ganaderos registrar y gestionar su ganado, predios y eventos relacionados con la actividad ganadera. Incluye funcionalidades avanzadas como lectura de códigos de barras, NFC, captura de ubicación GPS y carga de documentos.

## ✨ Características

### Autenticación de Usuarios
- Interfaz unificada con tabs (Iniciar Sesión / Registrarse)
- Registro con validación de INE y CURP (formato automático en mayúsculas)
- Autenticación JWT con manejo automático de sesiones
- Guardado opcional de credenciales
- Configuración de API personalizable (IP y puerto)
- Cierre de sesión automático ante respuestas 401 (no autenticado)
- Validación de contraseña con límite de 72 caracteres

### Gestión de Ganado
- **Registro de ganado:**
  - Escaneo de código de barras o tag NFC
  - Captura de foto de la nariz del animal para identificación biométrica
  - Selección de raza dominante mediante botones (8 opciones + "Otro")
  - Selección de propósito mediante botones (6 opciones + "Otro")
  - Selección de status mediante botones (7 opciones + "Otro")
  - Campos para identificación de madre, padre y predio de origen
- **Consulta de ganado:**
  - Vista detallada con diseño de cuadrícula organizada
  - Información estructurada en bloques: Identificación, Información General, Datos de Peso
  - Encabezado con gradiente y badge de status
- **Edición de ganado:**
  - Botón flotante de edición en la vista detallada
  - Interfaz idéntica al registro con datos pre-cargados
- **Selección múltiple:**
  - Modo de selección múltiple con checkboxes
  - Registro de eventos masivos para varios animales simultáneamente
- **Historial de eventos:**
  - Visualización por tipo de evento
  - Detalles de peso mostrando peso nuevo y peso anterior

### Gestión de Predios
- Registro de predios con captura de ubicación GPS automática
- Modal bottom sheet optimizado para móviles (reemplaza diálogos)
- Carga de documentos (comprobante de propiedad, uso de suelo)
- Lista y detalles de predios registrados
- Manejo adaptativo de teclado en formularios

### Registro de Eventos
- **9 tipos de eventos disponibles:**
  - Peso (con historial de peso anterior)
  - Dieta
  - Vacunación
  - Desparasitación
  - Laboratorio
  - Compra/Venta
  - Traslado
  - Enfermedad
  - Tratamiento
- Registro individual o múltiple (selección masiva)
- Historial completo de eventos agrupados por tipo
- Visualización de eventos con detalles específicos según el tipo

### Perfil de Usuario
- Visualización de datos personales
- Carga de documentos (INE frontal/trasera, comprobante de domicilio)
- Botón de cierre de sesión destacado
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
- NSCameraUsageDescription (cámara para fotos de nariz y documentos)
- NSLocationWhenInUseUsageDescription (GPS para predios)
- NSPhotoLibraryUsageDescription (galería de fotos)
- NFCReaderUsageDescription (lectura de tags NFC)

## 🎨 Características de Diseño

### Material Design 3
- Paleta de colores consistente con tema verde para ganadería
- Tipografía Roboto con jerarquía clara
- Elevaciones y sombras sutiles para profundidad

### Componentes Personalizados
- **Button Groups:** ChoiceChip wraps para opciones múltiples (raza, propósito, status)
- **Grid Layout:** Cards con iconos para información estructurada
- **Modal Sheets:** Bottom sheets con bordes redondeados y manejo de teclado
- **FABs Extendidos:** Botones flotantes con etiquetas para mejor UX
- **Gradientes:** Headers con gradientes para destacar información clave

### Responsive & Adaptativo
- Diseño optimizado para pantallas móviles
- Manejo automático de teclado en formularios
- ScrollController para listas largas
- SafeArea para notches y barras de sistema

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

### Primer Uso
1. **Configuración inicial:**
   - Presiona el ícono de engranaje (⚙️) en la pantalla de autenticación
   - Configura la dirección del servidor API si es diferente a la predeterminada
   - Guarda los cambios

2. **Registro de usuario:**
   - En la pantalla de autenticación, ve a la tab "Registrarse"
   - Completa todos los campos requeridos
   - Ingresa CURP en mayúsculas (el campo formatea automáticamente)
   - Usa una contraseña de máximo 72 caracteres
   - Valida con INE y CURP
   - Envía el registro

3. **Inicio de sesión:**
   - Ve a la tab "Iniciar Sesión"
   - Ingresa CURP y contraseña
   - (Opcional) Activa "Recordar credenciales" para guardarlas
   - Presiona "Iniciar Sesión"

### Gestión de Ganado
1. **Registrar nuevo ganado:**
   - Desde el menú principal, selecciona "Ganado"
   - Presiona el botón verde "Registrar Ganado"
   - Escanea código de barras o tag NFC del animal
   - Selecciona raza dominante (8 opciones predefinidas o "Otro" para ingresar manualmente)
   - Selecciona propósito (6 opciones predefinidas o "Otro")
   - Selecciona status (7 opciones predefinidas o "Otro")
   - Captura foto de la nariz del animal (cámara o galería)
   - Completa campos adicionales (madre, padre, predio)
   - Guarda el registro

2. **Consultar ganado:**
   - Lista todos los animales registrados
   - Toca un animal para ver sus detalles en formato de cuadrícula
   - Revisa información organizada por bloques

3. **Editar ganado:**
   - En la vista detallada del animal, presiona el botón flotante de edición (lápiz)
   - Modifica los campos necesarios
   - Actualiza la foto de la nariz si es necesario
   - Guarda los cambios

4. **Selección múltiple:**
   - Presiona el botón naranja "Selección Múltiple"
   - Selecciona varios animales usando los checkboxes
   - Registra eventos para todos los seleccionados simultáneamente

5. **Consultar historial:**
   - En la vista detallada, revisa el historial de eventos agrupados por tipo
   - Para eventos de peso, se muestra el peso nuevo y el peso anterior

### Gestión de Predios
1. **Registrar predio:**
   - Accede a "Predios" desde el menú
   - Presiona "Registrar Predio"
   - Se abrirá un modal optimizado para móviles
   - Completa nombre y ubicación (GPS captura automáticamente)
   - Sube documentos requeridos (propiedad y uso de suelo)
   - Guarda el predio

2. **Consultar predios:**
   - Lista todos los predios registrados
   - Toca un predio para ver detalles y documentos

### Registro de Eventos
1. **Evento individual:**
   - Selecciona "Eventos" en el menú
   - Elige el animal para el evento
   - Selecciona el tipo de evento
   - Completa el formulario específico del evento
   - Envía el registro

2. **Evento múltiple:**
   - Activa el modo de selección múltiple en la lista de ganado
   - Selecciona los animales
   - Registra el evento (se aplicará a todos los seleccionados)

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada con navegación global
├── models/                             # Modelos de datos
│   ├── user.dart                       # Usuario con validación de CURP
│   ├── bovino.dart                     # Ganado con campos extendidos
│   ├── predio.dart                     # Predios con GPS
│   └── evento.dart                     # 9 tipos de eventos (incluyendo PesoEvento)
├── services/                           # Servicios de API y lógica de negocio
│   ├── api_client.dart                 # Cliente Dio con interceptores JWT y manejo 401
│   ├── auth_service.dart               # Autenticación y registro
│   ├── bovino_service.dart             # CRUD de ganado + upload de foto nariz
│   ├── predio_service.dart             # CRUD de predios
│   ├── evento_service.dart             # Registro de eventos por tipo
│   └── file_service.dart               # Carga de documentos multipart
├── screens/                            # Pantallas de la aplicación
│   ├── auth/
│   │   ├── auth_screen.dart            # Autenticación con tabs (Login/Signup)
│   │   └── signup_screen.dart          # Formulario de registro
│   ├── home/
│   │   └── home_screen.dart            # Pantalla principal con navegación
│   ├── cattle/
│   │   ├── cattle_list_screen.dart     # Lista con selección múltiple
│   │   ├── register_cattle_screen.dart # Registro con button groups y foto nariz
│   │   ├── edit_cattle_screen.dart     # Edición con datos pre-cargados
│   │   └── cattle_detail_screen.dart   # Vista detallada con diseño grid
│   ├── predios/
│   │   ├── predios_screen.dart         # Lista + modal de registro
│   │   └── predio_detail_screen.dart   # Detalles del predio
│   ├── events/
│   │   └── register_event_screen.dart  # Registro de eventos por tipo
│   ├── profile/
│   │   └── profile_screen.dart         # Perfil con carga de documentos
│   └── settings/
│       └── api_settings_screen.dart    # Configuración de IP/Puerto API
├── utils/                              # Utilidades
│   └── curp_validator.dart             # Validador RFC de CURP
└── widgets/                            # Widgets reutilizables
    └── (componentes compartidos)
```

## 🔧 Tecnologías Utilizadas

- **Framework:** Flutter 3.7.2+ con Material Design 3
- **Lenguaje:** Dart 2.19.0+
- **HTTP Client:** dio (^5.4.0) con interceptores JWT
- **Almacenamiento Seguro:** flutter_secure_storage (^9.0.0) para tokens y credenciales
- **Gestión de Estado:** provider (^6.1.1), StatefulWidget, GlobalKey<NavigatorState>
- **Imágenes:** image_picker (^1.0.7) para fotos de nariz y documentos
- **Ubicación:** geolocator (^11.0.0), permission_handler (^11.2.0)
- **Escaneo:** mobile_scanner (^3.5.5) para códigos de barras, nfc_manager (^3.3.0)
- **Internacionalización:** intl (^0.19.0)
- **UI Components:** ChoiceChip, Modal Bottom Sheets, FloatingActionButton.extended

### Patrones y Arquitectura
- **Autenticación:** JWT con refresh automático y manejo global de errores 401
- **Navegación:** GlobalKey para navegación desde interceptores
- **Formularios:** Button groups con ChoiceChip para opciones múltiples
- **Upload:** Multipart/form-data para fotos y documentos
- **UX Móvil:** Modal bottom sheets, FABs extendidos, diseño grid responsivo

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
