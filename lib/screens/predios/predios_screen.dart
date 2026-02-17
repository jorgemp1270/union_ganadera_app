import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
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
      appBar: const ModernAppBar(
        title: 'Mis Predios',
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _predios.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes predios registrados',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadPredios,
                child: ListView.builder(
                  itemCount: _predios.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final predio = _predios[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          predio.claveCatastral ?? 'Sin clave catastral',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (predio.superficieTotal != null)
                              Text(
                                'Superficie: ${predio.superficieTotal} hectáreas',
                              ),
                            if (predio.latitud != null &&
                                predio.longitud != null)
                              Text(
                                'Lat: ${predio.latitud}, Long: ${predio.longitud}',
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to predio detail if needed
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showRegisterPredioDialog();
        },
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Predio'),
      ),
    );
  }

  Future<void> _showRegisterPredioDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _RegisterPredioDialog(
            predioService: _predioService,
            onSuccess: _loadPredios,
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
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _documentFile = File(image.path));
    }
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
      // 1. Create predio
      final predio = Predio(
        id: '',
        claveCatastral: _claveCatastralController.text.trim(),
        superficieTotal: double.tryParse(
          _superficieTotalController.text.trim(),
        ),
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
      );

      await widget.predioService.createPredio(predio);

      // 2. Upload document
      await _fileService.uploadFile(
        file: _documentFile!,
        docType: DocType.predio,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Registrar Predio',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _claveCatastralController,
                  decoration: const InputDecoration(
                    labelText: 'Clave Catastral',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _superficieTotalController,
                  decoration: const InputDecoration(
                    labelText: 'Superficie Total (hectáreas)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon:
                      _isLoadingLocation
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            _currentPosition == null
                                ? Icons.location_searching
                                : Icons.check_circle,
                          ),
                  label: Text(
                    _currentPosition == null
                        ? 'Obtener Ubicación'
                        : 'Ubicación Obtenida',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentPosition == null ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                      'Long: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: Icon(
                    _documentFile == null
                        ? Icons.camera_alt
                        : Icons.check_circle,
                  ),
                  label: Text(
                    _documentFile == null
                        ? 'Adjuntar Comprobante'
                        : 'Comprobante adjunto',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        _documentFile == null ? Colors.blue : Colors.green,
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
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
