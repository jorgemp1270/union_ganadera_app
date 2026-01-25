# Unión Ganadera - Flutter App

Una aplicación móvil completa para la gestión de ganado de la Unión Ganadera, desarrollada en Flutter.

## Características Principales

### Autenticación y Registro
- ✅ Registro de usuarios (ganaderos) con validación de datos del INE
- ✅ Validación automática de CURP usando algoritmo traducido de Java
- ✅ Carga de fotografías de INE y comprobante de domicilio
- ✅ Banner de advertencia para que los datos coincidan con el INE
- ✅ Login seguro con almacenamiento de tokens

### Gestión de Ganado (Bovinos)
- ✅ Lista completa de todo el ganado del usuario
- ✅ Búsqueda y filtrado por arete o raza
- ✅ Registro de nuevo ganado con:
  - Escaneo de código de barras (SIINIGA)
  - Escaneo NFC para aretes RFID
  - Información detallada (raza, sexo, peso, propósito)
- ✅ Detalle de cada bovino con historial completo
- ✅ Registro de eventos (peso, dieta, etc.)

### Gestión de Predios
- ✅ Lista de predios registrados
- ✅ Registro de nuevos predios con:
  - Obtención automática de coordenadas GPS
  - Carga de documentos comprobatorios (escrituras, predial)
  - Información catastral

### Perfil de Usuario
- ✅ Visualización de información del usuario
- ✅ Estado de documentos (autorizados/pendientes)
- ✅ Lista de todos los documentos subidos
- ✅ Indicadores visuales de autorización

### Eventos para Ganado
- ✅ Registro de eventos individuales o masivos
- ✅ Tipos de eventos: peso, dieta, vacunación, etc.
- ✅ Historial completo por bovino

## Tecnologías Utilizadas

### Dependencias Principales
- **dio**: Cliente HTTP para consumir la API REST
- **flutter_secure_storage**: Almacenamiento seguro de tokens
- **image_picker**: Captura de fotos de documentos
- **geolocator**: Obtención de coordenadas GPS
- **permission_handler**: Gestión de permisos
- **mobile_scanner**: Escaneo de códigos de barras
- **nfc_manager**: Lectura de tags NFC/RFID
- **provider**: Gestión de estado (preparado para uso futuro)
- **intl**: Formateo de fechas

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── models/                      # Modelos de datos
│   ├── user.dart
│   ├── bovino.dart
│   ├── predio.dart
│   ├── domicilio.dart
│   ├── document_file.dart
│   └── evento.dart
├── services/                    # Servicios para API
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── bovino_service.dart
│   ├── predio_service.dart
│   ├── file_service.dart
│   └── evento_service.dart
├── screens/                     # Pantallas de la UI
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── cattle/
│   │   ├── cattle_list_screen.dart
│   │   ├── cattle_detail_screen.dart
│   │   └── register_cattle_screen.dart
│   ├── predios/
│   │   └── predios_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── events/
│       └── register_event_screen.dart
└── utils/
    └── curp_validator.dart      # Validador de CURP (traducido de Java)
```

## Configuración y Ejecución

### Prerrequisitos
- Flutter SDK 3.7.2 o superior
- Dart SDK compatible
- Android Studio o Xcode (según plataforma)

### Instalación

1. Clonar el repositorio
2. Instalar dependencias:
```bash
flutter pub get
```

3. Configurar la URL base de la API en `lib/services/api_client.dart`:
```dart
static const String baseUrl = 'http://tu-servidor:8000';
```

4. Ejecutar la aplicación:
```bash
flutter run
```

## Características de Seguridad

- ✅ Almacenamiento seguro de tokens JWT con `flutter_secure_storage`
- ✅ Interceptores para añadir automáticamente tokens de autenticación
- ✅ Manejo automático de sesiones expiradas (401)
- ✅ Validación de CURP contra datos personales

## Validación de CURP

El algoritmo de validación de CURP ha sido traducido del código Java original:
- Valida formato de 18 caracteres
- Compara con datos personales (nombre, apellidos, fecha de nacimiento)
- Elimina palabras antisonantes
- Maneja casos especiales (María, José)

## API Integration

La aplicación consume la API documentada en `API_DOCUMENTATION.md` con los siguientes endpoints:

### Autenticación
- `POST /signup` - Registro de usuarios
- `POST /login` - Inicio de sesión
- `GET /users/me` - Información del usuario actual

### Bovinos
- `GET /bovinos/` - Listar ganado
- `POST /bovinos/` - Registrar ganado
- `PUT /bovinos/{id}` - Actualizar ganado
- `DELETE /bovinos/{id}` - Eliminar ganado

### Predios
- `GET /predios/` - Listar predios
- `POST /predios/` - Registrar predio
- `PUT /predios/{id}` - Actualizar predio
- `DELETE /predios/{id}` - Eliminar predio

### Archivos
- `GET /files/` - Listar documentos
- `POST /files/upload` - Subir documentos

### Eventos
- `GET /eventos/` - Listar eventos
- `POST /eventos/` - Registrar eventos

## Permisos Requeridos

### Android
- Cámara (para fotos de documentos)
- Ubicación (para coordenadas de predios)
- NFC (para lectura de aretes RFID)

### iOS
- Cámara
- Ubicación
- NFC (solo iPhone 7+)

## Próximas Mejoras

- [ ] Modo offline con sincronización
- [ ] Notificaciones push para eventos
- [ ] Reportes y estadísticas
- [ ] Integración con mapas para visualizar predios
- [ ] Exportación de datos a PDF/Excel

## Créditos

- Algoritmo de validación CURP: Jorge Muñoz Piñera (No. Control: 21041270)
- Desarrollo Flutter: Equipo Unión Ganadera
- API Backend: Ver API_DOCUMENTATION.md

## Licencia

Aplicación privada para uso exclusivo de la Unión Ganadera.
