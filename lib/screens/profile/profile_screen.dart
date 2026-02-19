import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/screens/auth/auth_screen.dart';
import 'package:union_ganadera_app/screens/settings/api_settings_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;
  late final FileService _fileService;

  User? _currentUser;
  List<DocumentFile> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  File? _ineFrontImage;
  File? _ineBackImage;
  File? _comprobanteDomicilioImage;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _fileService = FileService(_apiClient);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      final documents = await _fileService.getFiles();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _documents = documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
    return null;
  }

  Future<void> _showImageSourceDialog(Function(File) onImageSelected) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar Imagen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.camera);
                    if (image != null) {
                      onImageSelected(image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.gallery);
                    if (image != null) {
                      onImageSelected(image);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadDocuments() async {
    if (_ineFrontImage == null &&
        _ineBackImage == null &&
        _comprobanteDomicilioImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un documento')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload INE front
      if (_ineFrontImage != null) {
        await _fileService.uploadFile(
          file: _ineFrontImage!,
          docType: DocType.identificacion,
        );
      }

      // Upload INE back
      if (_ineBackImage != null) {
        await _fileService.uploadFile(
          file: _ineBackImage!,
          docType: DocType.identificacion,
        );
      }

      // Upload comprobante de domicilio
      if (_comprobanteDomicilioImage != null) {
        await _fileService.uploadFile(
          file: _comprobanteDomicilioImage!,
          docType: DocType.comprobanteDomicilio,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documentos subidos exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _ineFrontImage = null;
          _ineBackImage = null;
          _comprobanteDomicilioImage = null;
        });
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documentos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'Mi Perfil'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Profile Header Card ─────────────────────────────
                      Card(
                        color: cs.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: cs.primary,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: cs.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _currentUser?.curp ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(_currentUser?.rol ?? 'usuario'),
                                backgroundColor: cs.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Document Upload ─────────────────────────────────
                      Text(
                        'Subir Documentos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Documentos Requeridos',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              // INE Front
                              _DocUploadTile(
                                label: 'INE — Frente',
                                image: _ineFrontImage,
                                disabled: _isUploading,
                                onTap:
                                    () => _showImageSourceDialog(
                                      (img) =>
                                          setState(() => _ineFrontImage = img),
                                    ),
                                onRemove:
                                    () => setState(() => _ineFrontImage = null),
                              ),
                              const SizedBox(height: 10),
                              // INE Back
                              _DocUploadTile(
                                label: 'INE — Reverso',
                                image: _ineBackImage,
                                disabled: _isUploading,
                                onTap:
                                    () => _showImageSourceDialog(
                                      (img) =>
                                          setState(() => _ineBackImage = img),
                                    ),
                                onRemove:
                                    () => setState(() => _ineBackImage = null),
                              ),
                              const SizedBox(height: 10),
                              // Comprobante domicilio
                              _DocUploadTile(
                                label: 'Comprobante de Domicilio',
                                image: _comprobanteDomicilioImage,
                                disabled: _isUploading,
                                onTap:
                                    () => _showImageSourceDialog(
                                      (img) => setState(
                                        () => _comprobanteDomicilioImage = img,
                                      ),
                                    ),
                                onRemove:
                                    () => setState(
                                      () => _comprobanteDomicilioImage = null,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed:
                                    _isUploading ? null : _uploadDocuments,
                                icon:
                                    _isUploading
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.upload_rounded),
                                label: Text(
                                  _isUploading
                                      ? 'Subiendo...'
                                      : 'Subir Documentos',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Document Status ─────────────────────────────────
                      const SizedBox(height: 20),
                      Text(
                        'Estado de Documentos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_documents.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No has subido documentos',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documents.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            final authorized = doc.authored;
                            return Card(
                              color:
                                  authorized
                                      ? cs.secondaryContainer
                                      : cs.tertiaryContainer,
                              child: ListTile(
                                leading: Icon(
                                  _getDocumentIcon(doc.docType),
                                  color:
                                      authorized
                                          ? cs.onSecondaryContainer
                                          : cs.onTertiaryContainer,
                                ),
                                title: Text(
                                  _getDocumentTypeName(doc.docType),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        authorized
                                            ? cs.onSecondaryContainer
                                            : cs.onTertiaryContainer,
                                  ),
                                ),
                                subtitle: Text(
                                  doc.originalFilename,
                                  style: TextStyle(
                                    color:
                                        authorized
                                            ? cs.onSecondaryContainer
                                                .withOpacity(0.7)
                                            : cs.onTertiaryContainer
                                                .withOpacity(0.7),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        authorized ? cs.secondary : cs.tertiary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    authorized ? 'Autorizado' : 'Pendiente',
                                    style: TextStyle(
                                      color:
                                          authorized
                                              ? cs.onSecondary
                                              : cs.onTertiary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // ── Info Notice ─────────────────────────────────────
                      const SizedBox(height: 16),
                      Card(
                        color: cs.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: cs.onTertiaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Los documentos pendientes serán revisados por un administrador. '
                                  'Una vez autorizados, tendrás acceso completo a todas las funciones.',
                                  style: TextStyle(
                                    color: cs.onTertiaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Actions ─────────────────────────────────────────
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApiSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Configuración de API'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar Sesión'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.errorContainer,
                          foregroundColor: cs.onErrorContainer,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  IconData _getDocumentIcon(String docType) {
    switch (docType) {
      case 'identificacion':
        return Icons.credit_card;
      case 'comprobante_domicilio':
        return Icons.home;
      case 'predio':
        return Icons.location_on;
      case 'cedula_veterinario':
        return Icons.medical_services;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeName(String docType) {
    switch (docType) {
      case 'identificacion':
        return 'Identificación (INE)';
      case 'comprobante_domicilio':
        return 'Comprobante de Domicilio';
      case 'predio':
        return 'Documento de Predio';
      case 'cedula_veterinario':
        return 'Cédula Veterinaria';
      default:
        return 'Otro Documento';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Reusable document upload tile
// ────────────────────────────────────────────────────────────────────────────

class _DocUploadTile extends StatelessWidget {
  final String label;
  final File? image;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DocUploadTile({
    required this.label,
    required this.image,
    required this.disabled,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = image != null;

    return Material(
      color: hasImage ? cs.secondaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: SizedBox(
          height: 112,
          child:
              hasImage
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image!, fit: BoxFit.cover),
                      // Dark scrim at top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black45, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 10,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: cs.error,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onRemove,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: cs.onError,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
