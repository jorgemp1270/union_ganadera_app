import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
import 'package:union_ganadera_app/screens/predios/predio_detail_screen.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class PrediosScreen extends StatefulWidget {
  const PrediosScreen({super.key});

  @override
  State<PrediosScreen> createState() => _PrediosScreenState();
}

class _PrediosScreenState extends State<PrediosScreen> {
  final ApiClient _apiClient = ApiClient();
  late final PredioService _predioService;
  List<Predio> _predios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _predioService = PredioService(_apiClient);
    _loadPredios();
  }

  Future<void> _loadPredios() async {
    setState(() => _isLoading = true);
    try {
      final predios = await _predioService.getPredios();
      if (mounted) {
        setState(() {
          _predios = predios;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'Mis Predios'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _predios.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadPredios,
                child: ListView.builder(
                  itemCount: _predios.length,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemBuilder: (context, index) {
                    final predio = _predios[index];
                    final cs = Theme.of(context).colorScheme;
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => PredioDetailScreen(predio: predio),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.landscape_rounded,
                                  color: cs.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      predio.claveCatastral ??
                                          'Sin clave catastral',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (predio.superficieTotal != null)
                                      Text(
                                        '${predio.superficieTotal} hectáreas',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    if (predio.latitud != null &&
                                        predio.longitud != null)
                                      Text(
                                        'GPS: ${predio.latitud!.toStringAsFixed(4)}, ${predio.longitud!.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterPredioDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar Predio'),
      ),
    );
  }

  Future<void> _showRegisterPredioDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder:
          (context) => _RegisterPredioDialog(
            predioService: _predioService,
            onSuccess: _loadPredios,
          ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.landscape_outlined,
                size: 52,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin predios registrados',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón de abajo para registrar tu primera propiedad.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterPredioDialog extends StatefulWidget {
  final PredioService predioService;
  final VoidCallback onSuccess;

  const _RegisterPredioDialog({
    required this.predioService,
    required this.onSuccess,
  });

  @override
  State<_RegisterPredioDialog> createState() => _RegisterPredioDialogState();
}

class _RegisterPredioDialogState extends State<_RegisterPredioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _claveCatastralController = TextEditingController();
  final _superficieTotalController = TextEditingController();

  Position? _currentPosition;
  File? _documentFile;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  final ApiClient _apiClient = ApiClient();
  late final FileService _fileService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fileService = FileService(_apiClient);
  }

  @override
  void dispose() {
    _claveCatastralController.dispose();
    _superficieTotalController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Request location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        throw Exception('Permiso de ubicación denegado');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingLocation = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Future<void> _pickDocument() async {
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
                    final XFile? img = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (img != null) {
                      setState(() => _documentFile = File(img.path));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (img != null) {
                      setState(() => _documentFile = File(img.path));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file_rounded),
                  title: const Text('Seleccionar archivo (PDF, etc.)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      setState(
                        () => _documentFile = File(result.files.single.path!),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes obtener la ubicación del predio')),
      );
      return;
    }

    if (_documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes adjuntar un comprobante del predio'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create predio — capture the returned object to get its ID
      final predio = Predio(
        id: '',
        claveCatastral: _claveCatastralController.text.trim(),
        superficieTotal: double.tryParse(
          _superficieTotalController.text.trim(),
        ),
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
      );

      final createdPredio = await widget.predioService.createPredio(predio);

      // 2. Upload comprobante scoped to the new predio
      await _fileService.uploadPredioDocument(
        predioId: createdPredio.id,
        file: _documentFile!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Predio registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // drag handle area
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
                        'Registrar Predio',
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _claveCatastralController,
                  decoration: const InputDecoration(
                    labelText: 'Clave Catastral',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _superficieTotalController,
                  decoration: const InputDecoration(
                    labelText: 'Superficie Total (hectáreas)',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon:
                      _isLoadingLocation
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            _currentPosition == null
                                ? Icons.location_searching_rounded
                                : Icons.check_circle_outline_rounded,
                          ),
                  label: Text(
                    _currentPosition == null
                        ? 'Obtener Ubicación'
                        : 'Ubicación obtenida',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _currentPosition == null ? null : cs.secondaryContainer,
                    foregroundColor:
                        _currentPosition == null
                            ? null
                            : cs.onSecondaryContainer,
                  ),
                ),
                if (_currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                      'Long: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: Icon(
                    _documentFile == null
                        ? Icons.attach_file_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(
                    _documentFile == null
                        ? 'Adjuntar Comprobante'
                        : 'Comprobante adjunto',
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
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Registrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
