import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/domicilio.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/screens/auth/auth_screen.dart';
import 'package:union_ganadera_app/screens/predios/predio_detail_screen.dart';
import 'package:union_ganadera_app/screens/settings/api_settings_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/domicilio_service.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
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
  late final DomicilioService _domicilioService;
  late final PredioService _predioService;

  User? _currentUser;
  List<DocumentFile> _documents = [];
  Domicilio? _domicilio;
  List<Predio> _predios = [];
  Map<String, DocumentFile?> _predioDocuments = {};
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isLoadingPredios = false;
  final ImagePicker _picker = ImagePicker();

  File? _ineFrontImage;
  File? _ineBackImage;
  List<File> _fierroImages = [];
  bool _isFierroUploading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _fileService = FileService(_apiClient);
    _domicilioService = DomicilioService(_apiClient);
    _predioService = PredioService(_apiClient);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      final documents = await _fileService.getFiles();
      final domicilios = await _domicilioService.getDomicilios(limit: 1);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _documents = documents;
          _domicilio = domicilios.isNotEmpty ? domicilios.first : null;
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
    // Load predios and their documents in parallel (non-fatal)
    _loadPrediosWithDocs();
  }

  Future<void> _loadPrediosWithDocs() async {
    setState(() => _isLoadingPredios = true);
    try {
      final predios = await _predioService.getPredios();
      if (!mounted) return;
      setState(() => _predios = predios);

      // Fetch each predio's document in parallel
      if (predios.isNotEmpty) {
        final results = await Future.wait(
          predios.map((p) => _predioService.getDocument(p.id)),
        );
        if (!mounted) return;
        final docMap = <String, DocumentFile?>{};
        for (var i = 0; i < predios.length; i++) {
          docMap[predios[i].id] = results[i];
        }
        setState(() => _predioDocuments = docMap);
      }
    } catch (_) {
      // Non-fatal — section simply shows nothing
    } finally {
      if (mounted) setState(() => _isLoadingPredios = false);
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
    await showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tomar foto'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await _pickImage(ImageSource.camera);
                    if (image != null) onImageSelected(image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await _pickImage(ImageSource.gallery);
                    if (image != null) onImageSelected(image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file_rounded),
                  title: const Text('Seleccionar archivo (PDF, etc.)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await FilePicker.platform.pickFiles();
                    if (result?.files.single.path != null) {
                      onImageSelected(File(result!.files.single.path!));
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _uploadDocuments() async {
    if (_ineFrontImage == null && _ineBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un documento')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      if (_ineFrontImage != null) {
        await _fileService.uploadFile(
          file: _ineFrontImage!,
          docType: DocType.identificacionFrente,
        );
      }

      if (_ineBackImage != null) {
        await _fileService.uploadFile(
          file: _ineBackImage!,
          docType: DocType.identificacionReverso,
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

  Future<void> _uploadFierros() async {
    if (_fierroImages.isEmpty) return;
    setState(() => _isFierroUploading = true);
    try {
      for (final file in _fierroImages) {
        await _fileService.uploadFile(
          file: file,
          docType: DocType.fierroDeHerrar,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fierros subidos exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _fierroImages = []);
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir fierros: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFierroUploading = false);
    }
  }

  // ── Document actions ────────────────────────────────────────────────────

  Future<void> _deleteDocument(DocumentFile doc) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar documento'),
            content: Text(
              '¿Eliminar "${doc.originalFilename}"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _fileService.deleteFile(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(DocumentFile doc) async {
    if (doc.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL de descarga no disponible')),
      );
      return;
    }

    final uri = Uri.parse(doc.downloadUrl!);
    final isImage = _isImageFile(doc.originalFilename);

    if (isImage) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(doc.originalFilename),
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      doc.downloadUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, _) => Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No se pudo cargar la imagen',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final u = Uri.parse(doc.downloadUrl!);
                                  try {
                                    await launchUrl(
                                      u,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se pudo abrir en navegador',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  color: Colors.white70,
                                ),
                                label: const Text(
                                  'Abrir en navegador',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
        ),
      );
    } else {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el documento')),
          );
        }
      }
    }
  }

  bool _isImageFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);
  }

  // ── Domicilio ───────────────────────────────────────────────────────────

  Future<void> _showDomicilioForm({Domicilio? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _DomicilioFormSheet(
            domicilioService: _domicilioService,
            existing: existing,
            onSuccess: _loadUserData,
          ),
    );
  }

  Future<void> _pickAndUploadComprobante() async {
    if (_domicilio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registra tu domicilio primero para subir el comprobante',
          ),
        ),
      );
      return;
    }

    File? picked;
    picked = await showModalBottomSheet<File?>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tomar foto'),
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx, img != null ? File(img.path) : null);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx, img != null ? File(img.path) : null);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file_rounded),
                  title: const Text('Seleccionar archivo'),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (ctx.mounted) {
                      Navigator.pop(
                        ctx,
                        result?.files.single.path != null
                            ? File(result!.files.single.path!)
                            : null,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );

    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      await _domicilioService.uploadDocument(
        domicilioId: _domicilio!.id,
        file: picked,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante subido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

                      // ── Domicilio ────────────────────────────────────────
                      Text(
                        'Mi Domicilio',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDomicilioCard(cs),

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

                      // ── Fierro de Herrar Upload ──────────────────────────────────
                      const SizedBox(height: 20),
                      Text(
                        'Fierro de Herrar',
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
                                'Puedes subir varias fotos de tus fierros de herrar',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_fierroImages.isNotEmpty) ...[
                                ..._fierroImages.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department_outlined,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Fierro ${entry.key + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          onPressed:
                                              () => setState(
                                                () => _fierroImages.removeAt(
                                                  entry.key,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              OutlinedButton.icon(
                                onPressed:
                                    _isFierroUploading
                                        ? null
                                        : () => _showImageSourceDialog(
                                          (img) => setState(
                                            () => _fierroImages.add(img),
                                          ),
                                        ),
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: const Text('Agregar fierro'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                              ),
                              if (_fierroImages.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed:
                                      _isFierroUploading
                                          ? null
                                          : _uploadFierros,
                                  icon:
                                      _isFierroUploading
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
                                    _isFierroUploading
                                        ? 'Subiendo...'
                                        : 'Subir ${_fierroImages.length} fierro${_fierroImages.length == 1 ? '' : 's'}',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── Predios Document Status ─────────────────────────────────
                      const SizedBox(height: 20),
                      Text(
                        'Documentos de Predios',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingPredios)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_predios.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.landscape_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sin predios registrados',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _predios.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final predio = _predios[index];
                            final doc = _predioDocuments[predio.id];
                            final hasDoc = doc != null;
                            return Card(
                              color:
                                  hasDoc
                                      ? cs.secondaryContainer
                                      : cs.surfaceContainerHigh,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PredioDetailScreen(
                                            predio: predio,
                                          ),
                                    ),
                                  ).then((_) => _loadPrediosWithDocs());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    8,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.landscape_rounded,
                                        color:
                                            hasDoc
                                                ? cs.onSecondaryContainer
                                                : cs.onSurfaceVariant,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              predio.claveCatastral ??
                                                  'Predio ${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color:
                                                    hasDoc
                                                        ? cs.onSecondaryContainer
                                                        : cs.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              hasDoc
                                                  ? doc.originalFilename
                                                  : 'Sin documento',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    hasDoc
                                                        ? cs.onSecondaryContainer
                                                            .withOpacity(0.7)
                                                        : cs.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        hasDoc
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_amber_rounded,
                                        color:
                                            hasDoc
                                                ? Colors.green.shade600
                                                : cs.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color:
                                            hasDoc
                                                ? cs.onSecondaryContainer
                                                : cs.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // ── Document Status ─────────────────────────────────────────
                      const SizedBox(height: 20),
                      Text(
                        'Estado de Documentos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Required documents checklist ──────────────────
                      _buildRequiredDocsChecklist(cs),
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
                            final revision = doc.ultimaRevision;
                            final rejected =
                                !authorized && revision?.status == 'rechazado';
                            final pending = !authorized && revision == null;
                            // background color
                            final cardColor =
                                authorized
                                    ? cs.secondaryContainer
                                    : rejected
                                    ? cs.errorContainer
                                    : cs.tertiaryContainer;
                            final onCardColor =
                                authorized
                                    ? cs.onSecondaryContainer
                                    : rejected
                                    ? cs.onErrorContainer
                                    : cs.onTertiaryContainer;
                            // badge
                            final badgeLabel =
                                authorized
                                    ? 'Autorizado'
                                    : rejected
                                    ? 'Rechazado'
                                    : 'En revisión';
                            final badgeBg =
                                authorized
                                    ? cs.secondary
                                    : rejected
                                    ? cs.error
                                    : cs.tertiary;
                            final badgeFg =
                                authorized
                                    ? cs.onSecondary
                                    : rejected
                                    ? cs.onError
                                    : cs.onTertiary;
                            return Card(
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  6,
                                  6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getDocumentIcon(doc.docType),
                                          color: onCardColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getDocumentTypeName(
                                                  doc.docType,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: onCardColor,
                                                ),
                                              ),
                                              Text(
                                                doc.originalFilename,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: onCardColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            badgeLabel,
                                            style: TextStyle(
                                              color: badgeFg,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Rejection reason
                                    if (rejected &&
                                        revision!.comentario != null &&
                                        revision.comentario!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: cs.error.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              size: 14,
                                              color: onCardColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                revision.comentario!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: onCardColor,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Pending hint
                                    if (pending) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'En espera de revisión por un administrador.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: onCardColor.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (doc.downloadUrl != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.open_in_new_rounded,
                                              size: 18,
                                            ),
                                            tooltip: 'Ver documento',
                                            color: onCardColor,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () => _viewDocument(doc),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                          ),
                                          tooltip: 'Eliminar documento',
                                          color:
                                              rejected ? onCardColor : cs.error,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _deleteDocument(doc),
                                        ),
                                      ],
                                    ),
                                  ],
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
      case 'identificacion_frente':
        return Icons.credit_card_outlined;
      case 'identificacion_reverso':
        return Icons.credit_card;
      case 'comprobante_domicilio':
        return Icons.home;
      case 'predio':
        return Icons.location_on;
      case 'cedula_veterinario':
        return Icons.medical_services;
      case 'fierro':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeName(String docType) {
    switch (docType) {
      case 'identificacion_frente':
        return 'INE — Frente';
      case 'identificacion_reverso':
        return 'INE — Reverso';
      case 'comprobante_domicilio':
        return 'Comprobante de Domicilio';
      case 'predio':
        return 'Documento de Predio';
      case 'cedula_veterinario':
        return 'Cédula Veterinaria';
      case 'fierro':
        return 'Fierro de Herrar';
      default:
        return 'Otro Documento';
    }
  }

  Widget _buildRequiredDocsChecklist(ColorScheme cs) {
    final hasFrente = _documents.any(
      (d) => d.docType == 'identificacion_frente',
    );
    final hasReverso = _documents.any(
      (d) => d.docType == 'identificacion_reverso',
    );
    final hasComprobante = _documents.any(
      (d) => d.docType == 'comprobante_domicilio',
    );

    final items = [
      (
        label: 'INE — Frente',
        icon: Icons.credit_card_outlined,
        uploaded: hasFrente,
      ),
      (label: 'INE — Reverso', icon: Icons.credit_card, uploaded: hasReverso),
      (
        label: 'Comprobante de Domicilio',
        icon: Icons.home_outlined,
        uploaded: hasComprobante,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentos requeridos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      item.uploaded
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color:
                          item.uploaded
                              ? Colors.green.shade600
                              : cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(width: 10),
                    Icon(item.icon, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            item.uploaded ? cs.onSurface : cs.onSurfaceVariant,
                        fontWeight:
                            item.uploaded ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.uploaded ? 'Subido' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            item.uploaded
                                ? Colors.green.shade600
                                : cs.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomicilioCard(ColorScheme cs) {
    if (_domicilio == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.home_outlined, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(
                    'Sin domicilio registrado',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () => _showDomicilioForm(),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Registrar Domicilio'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _domicilio!;
    final parts = <String>[
      if (d.calle != null) d.calle!,
      if (d.colonia != null) 'Col. ${d.colonia!}',
      if (d.cp != null) 'C.P. ${d.cp!}',
      if (d.municipio != null) d.municipio!,
      if (d.estado != null) d.estado!,
    ];

    final hasComprobante = _documents.any(
      (doc) => doc.docType == 'comprobante_domicilio',
    );

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city_rounded, color: cs.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    parts.isNotEmpty
                        ? parts.join(', ')
                        : 'Domicilio registrado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: cs.onPrimaryContainer,
                  tooltip: 'Editar domicilio',
                  onPressed: () => _showDomicilioForm(existing: _domicilio),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadComprobante,
                    icon: Icon(
                      hasComprobante
                          ? Icons.upload_file_rounded
                          : Icons.upload_file_outlined,
                      size: 18,
                    ),
                    label: Text(
                      hasComprobante
                          ? 'Actualizar Comprobante'
                          : 'Subir Comprobante',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
// ────────────────────────────────────────────────────────────────────────────
// Domicilio form bottom sheet — create or edit
// ────────────────────────────────────────────────────────────────────────────

class _DomicilioFormSheet extends StatefulWidget {
  final DomicilioService domicilioService;
  final Domicilio? existing;
  final VoidCallback onSuccess;

  const _DomicilioFormSheet({
    required this.domicilioService,
    this.existing,
    required this.onSuccess,
  });

  @override
  State<_DomicilioFormSheet> createState() => _DomicilioFormSheetState();
}

class _DomicilioFormSheetState extends State<_DomicilioFormSheet> {
  final _calleController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _cpController = TextEditingController();
  final _estadoController = TextEditingController();
  final _municipioController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _calleController.text = d.calle ?? '';
      _coloniaController.text = d.colonia ?? '';
      _cpController.text = d.cp ?? '';
      _estadoController.text = d.estado ?? '';
      _municipioController.text = d.municipio ?? '';
    }
  }

  @override
  void dispose() {
    _calleController.dispose();
    _coloniaController.dispose();
    _cpController.dispose();
    _estadoController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updates = {
        if (_calleController.text.trim().isNotEmpty)
          'calle': _calleController.text.trim(),
        if (_coloniaController.text.trim().isNotEmpty)
          'colonia': _coloniaController.text.trim(),
        if (_cpController.text.trim().isNotEmpty)
          'cp': _cpController.text.trim(),
        if (_estadoController.text.trim().isNotEmpty)
          'estado': _estadoController.text.trim(),
        if (_municipioController.text.trim().isNotEmpty)
          'municipio': _municipioController.text.trim(),
      };

      if (widget.existing == null) {
        final domicilio = Domicilio(
          id: '',
          usuarioId: '',
          calle: updates['calle'],
          colonia: updates['colonia'],
          cp: updates['cp'],
          estado: updates['estado'],
          municipio: updates['municipio'],
        );
        await widget.domicilioService.createDomicilio(domicilio);
      } else {
        await widget.domicilioService.updateDomicilio(
          widget.existing!.id,
          updates,
        );
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Domicilio registrado'
                  : 'Domicilio actualizado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'Registrar Domicilio'
                          : 'Editar Domicilio',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _calleController,
                decoration: const InputDecoration(
                  labelText: 'Calle y número',
                  prefixIcon: Icon(Icons.streetview_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _coloniaController,
                      decoration: const InputDecoration(
                        labelText: 'Colonia',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cpController,
                      decoration: const InputDecoration(labelText: 'C.P.'),
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _municipioController,
                decoration: const InputDecoration(
                  labelText: 'Municipio',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _estadoController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: Text(
                      widget.existing == null ? 'Registrar' : 'Guardar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
