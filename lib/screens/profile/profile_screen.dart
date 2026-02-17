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
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
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
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Mi Perfil',
        backgroundColor: Colors.green,
      ),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.green.shade700,
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentUser?.curp ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(_currentUser?.rol ?? 'usuario'),
                                backgroundColor: Colors.green.shade100,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Subir Documentos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Documentos Requeridos',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              // INE Front
                              InkWell(
                                onTap:
                                    _isUploading
                                        ? null
                                        : () => _showImageSourceDialog((image) {
                                          setState(
                                            () => _ineFrontImage = image,
                                          );
                                        }),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      _ineFrontImage != null
                                          ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.file(
                                                  _ineFrontImage!,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => setState(
                                                        () =>
                                                            _ineFrontImage =
                                                                null,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 40,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'INE - Frente',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // INE Back
                              InkWell(
                                onTap:
                                    _isUploading
                                        ? null
                                        : () => _showImageSourceDialog((image) {
                                          setState(() => _ineBackImage = image);
                                        }),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      _ineBackImage != null
                                          ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.file(
                                                  _ineBackImage!,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => setState(
                                                        () =>
                                                            _ineBackImage =
                                                                null,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 40,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'INE - Reverso',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Comprobante de Domicilio
                              InkWell(
                                onTap:
                                    _isUploading
                                        ? null
                                        : () => _showImageSourceDialog((image) {
                                          setState(
                                            () =>
                                                _comprobanteDomicilioImage =
                                                    image,
                                          );
                                        }),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      _comprobanteDomicilioImage != null
                                          ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.file(
                                                  _comprobanteDomicilioImage!,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => setState(
                                                        () =>
                                                            _comprobanteDomicilioImage =
                                                                null,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 40,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Comprobante de Domicilio',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed:
                                    _isUploading ? null : _uploadDocuments,
                                icon:
                                    _isUploading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.upload),
                                label: Text(
                                  _isUploading
                                      ? 'Subiendo...'
                                      : 'Subir Documentos',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Estado de Documentos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_documents.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('No has subido documentos'),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  _getDocumentIcon(doc.docType),
                                  color:
                                      doc.authored
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                                title: Text(_getDocumentTypeName(doc.docType)),
                                subtitle: Text(doc.originalFilename),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        doc.authored
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    doc.authored ? 'Autorizado' : 'Pendiente',
                                    style: TextStyle(
                                      color:
                                          doc.authored
                                              ? Colors.green.shade900
                                              : Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los documentos pendientes serán revisados por un administrador. '
                              'Una vez autorizados, tendrás acceso completo a todas las funciones.',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApiSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configuración de API'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
