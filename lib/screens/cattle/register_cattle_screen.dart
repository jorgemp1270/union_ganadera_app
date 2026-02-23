import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class RegisterCattleScreen extends StatefulWidget {
  const RegisterCattleScreen({super.key});

  @override
  State<RegisterCattleScreen> createState() => _RegisterCattleScreenState();
}

class _RegisterCattleScreenState extends State<RegisterCattleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _areteBarcodeController = TextEditingController();
  final _areteRfidController = TextEditingController();
  final _razaDominanteController = TextEditingController();
  final _pesoNacController = TextEditingController();
  final _pesoActualController = TextEditingController();
  final _propositoController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _sexo = 'M';
  String? _selectedRaza;
  String? _selectedProposito;
  String? _selectedStatus;
  bool _showOtherRaza = false;
  bool _showOtherProposito = false;
  bool _showOtherStatus = false;
  File? _nosePhoto;
  bool _isLoading = false;
  bool _nfcAvailable = false;
  List<Predio> _predios = [];
  String? _selectedPredioId;
  bool _isLoadingPredios = false;
  List<Bovino> _allBovinos = [];
  String? _selectedMadreId;
  String? _selectedPadreId;
  bool _isLoadingBovinos = false;

  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
  late final PredioService _predioService;
  final ImagePicker _imagePicker = ImagePicker();
  final _statusController = TextEditingController();

  // Lista de razas comunes
  final List<String> _razas = [
    'Angus',
    'Hereford',
    'Charolais',
    'Simmental',
    'Brahman',
    'Holstein',
    'Jersey',
    'Otro',
  ];

  // Lista de propósitos
  final List<String> _propositos = [
    'Engorda',
    'Reproducción',
    'Lechero',
    'Doble Propósito',
    'Lidia',
    'Otro',
  ];

  // Lista de estados
  final List<String> _estados = [
    'activo',
    'vendido',
    'muerto',
    'enfermo',
    'en tratamiento',
    'en cuarentena',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _predioService = PredioService(_apiClient);
    _checkNfcAvailability();
    _loadPredios();
    _loadBovinos();
  }

  Future<void> _loadPredios() async {
    setState(() => _isLoadingPredios = true);
    try {
      final predios = await _predioService.getPredios();
      if (mounted) setState(() => _predios = predios);
    } catch (_) {
      // Non-critical — form still works without predios loaded
    } finally {
      if (mounted) setState(() => _isLoadingPredios = false);
    }
  }

  Future<void> _loadBovinos() async {
    setState(() => _isLoadingBovinos = true);
    try {
      final bovinos = await _bovinoService.getBovinos();
      if (mounted) setState(() => _allBovinos = bovinos);
    } catch (_) {
      // Non-critical
    } finally {
      if (mounted) setState(() => _isLoadingBovinos = false);
    }
  }

  String _bovinoLabel(Bovino b) =>
      b.nombre ??
      b.areteBarcode ??
      b.areteRfid ??
      b.folio ??
      b.id.substring(0, 8);

  @override
  void dispose() {
    _nombreController.dispose();
    _areteBarcodeController.dispose();
    _areteRfidController.dispose();
    _razaDominanteController.dispose();
    _pesoNacController.dispose();
    _pesoActualController.dispose();
    _propositoController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final isAvailable = await NfcManager.instance.isAvailable();
      setState(() => _nfcAvailable = isAvailable);
    }
  }

  Future<void> _scanBarcode() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Escanear Código de Barras'),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              body: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      setState(() {
                        _areteBarcodeController.text = code;
                      });
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ),
      ),
    );
  }

  Future<void> _scanNFC() async {
    if (!_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC no disponible en este dispositivo')),
      );
      return;
    }

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndefMessage = tag.data['ndef'];
          if (ndefMessage != null) {
            // Extract NFC data here
            setState(() {
              _areteRfidController.text =
                  tag.data['nfca']?['identifier']?.toString() ?? '';
            });
          }
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al leer NFC: $e')));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _pickNosePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() => _nosePhoto = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _pickNosePhotoFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() => _nosePhoto = File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al seleccionar foto: $e')));
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine raza dominante
      String? razaDominante;
      if (_selectedRaza != null) {
        if (_selectedRaza == 'Otro') {
          razaDominante =
              _razaDominanteController.text.trim().isEmpty
                  ? null
                  : _razaDominanteController.text.trim();
        } else {
          razaDominante = _selectedRaza;
        }
      }

      // Determine proposito
      String? proposito;
      if (_selectedProposito != null) {
        if (_selectedProposito == 'Otro') {
          proposito =
              _propositoController.text.trim().isEmpty
                  ? null
                  : _propositoController.text.trim();
        } else {
          proposito = _selectedProposito;
        }
      }

      // Determine status
      String status = 'activo'; // Default
      if (_selectedStatus != null) {
        if (_selectedStatus == 'Otro') {
          status =
              _statusController.text.trim().isEmpty
                  ? 'activo'
                  : _statusController.text.trim();
        } else {
          status = _selectedStatus!;
        }
      }

      final bovino = Bovino(
        id: '',
        usuarioId: '',
        nombre:
            _nombreController.text.trim().isEmpty
                ? null
                : _nombreController.text.trim(),
        areteBarcode:
            _areteBarcodeController.text.trim().isEmpty
                ? null
                : _areteBarcodeController.text.trim(),
        areteRfid:
            _areteRfidController.text.trim().isEmpty
                ? null
                : _areteRfidController.text.trim(),
        razaDominante: razaDominante,
        fechaNac: _fechaNacimiento,
        sexo: _sexo,
        pesoNac:
            _pesoNacController.text.trim().isEmpty
                ? null
                : double.tryParse(_pesoNacController.text.trim()),
        pesoActual:
            _pesoActualController.text.trim().isEmpty
                ? null
                : double.tryParse(_pesoActualController.text.trim()),
        proposito: proposito,
        predioId: _selectedPredioId,
        madreId: _selectedMadreId,
        padreId: _selectedPadreId,
        status: status,
      );

      final createdBovino = await _bovinoService.createBovino(bovino);

      // Upload nose photo if selected
      if (_nosePhoto != null) {
        try {
          await _bovinoService.uploadNosePhoto(createdBovino.id, _nosePhoto!);
        } catch (e) {
          // Show warning but don't fail the registration
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ganado registrado, pero error al subir foto: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ganado registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

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
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Registrar Ganado',
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Identificación SIINIGA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areteBarcodeController,
                decoration: InputDecoration(
                  labelText: 'Arete Código de Barras',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areteRfidController,
                decoration: InputDecoration(
                  labelText: 'Arete RFID/NFC',
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      _nfcAvailable
                          ? IconButton(
                            icon: const Icon(Icons.nfc),
                            onPressed: _scanNFC,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Información del Ganado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre (Opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Torito',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const Text(
                'Raza Dominante',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _razas.map((raza) {
                      final isSelected = _selectedRaza == raza;
                      return ChoiceChip(
                        label: Text(raza),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRaza = selected ? raza : null;
                            _showOtherRaza = raza == 'Otro' && selected;
                          });
                        },
                        selectedColor: Colors.green.shade300,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
              ),
              if (_showOtherRaza) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _razaDominanteController,
                  decoration: const InputDecoration(
                    labelText: 'Especificar Raza',
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa la raza',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Propósito',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _propositos.map((proposito) {
                      final isSelected = _selectedProposito == proposito;
                      return ChoiceChip(
                        label: Text(proposito),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedProposito = selected ? proposito : null;
                            _showOtherProposito =
                                proposito == 'Otro' && selected;
                          });
                        },
                        selectedColor: Colors.green.shade300,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
              ),
              if (_showOtherProposito) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _propositoController,
                  decoration: const InputDecoration(
                    labelText: 'Especificar Propósito',
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el propósito',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexo,
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Macho')),
                  DropdownMenuItem(value: 'F', child: Text('Hembra')),
                ],
                onChanged: (value) => setState(() => _sexo = value!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fechaNacimiento == null
                        ? 'Selecciona la fecha'
                        : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoNacController,
                decoration: const InputDecoration(
                  labelText: 'Peso al Nacer (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoActualController,
                decoration: const InputDecoration(
                  labelText: 'Peso Actual (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              const Text(
                'Estado del Ganado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _estados.map((estado) {
                      final isSelected = _selectedStatus == estado;
                      return ChoiceChip(
                        label: Text(estado),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? estado : null;
                            _showOtherStatus = estado == 'Otro' && selected;
                          });
                        },
                        selectedColor: Colors.green.shade300,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
              ),
              if (_showOtherStatus) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'Especificar Estado',
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el estado',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Genealogía (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoadingBovinos)
                const LinearProgressIndicator()
              else ...[
                DropdownButtonFormField<String?>(
                  value: _selectedMadreId,
                  decoration: const InputDecoration(
                    labelText: 'Madre (Opcional)',
                    prefixIcon: Icon(Icons.female_rounded),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin madre registrada'),
                    ),
                    ..._allBovinos
                        .where((b) => b.sexo == 'F')
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              _bovinoLabel(b),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _selectedMadreId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedPadreId,
                  decoration: const InputDecoration(
                    labelText: 'Padre (Opcional)',
                    prefixIcon: Icon(Icons.male_rounded),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin padre registrado'),
                    ),
                    ..._allBovinos
                        .where((b) => b.sexo == 'M')
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              _bovinoLabel(b),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _selectedPadreId = v),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Ubicación (Predio)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoadingPredios)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String?>(
                  value: _selectedPredioId,
                  decoration: const InputDecoration(
                    labelText: 'Predio (Opcional)',
                    prefixIcon: Icon(Icons.landscape_rounded),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  selectedItemBuilder:
                      (context) => [
                        const Text('Sin predio'),
                        ..._predios.map(
                          (p) => Text(
                            p.claveCatastral ?? 'Sin clave catastral',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin predio'),
                    ),
                    ..._predios.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: _PredioDropdownItem(predio: p),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedPredioId = v),
                ),
              const SizedBox(height: 24),
              const Text(
                'Foto de la Nariz (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'La nariz del ganado es única como una huella digital',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_nosePhoto != null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_nosePhoto!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickNosePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickNosePhotoFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_nosePhoto != null)
                TextButton.icon(
                  onPressed: () => setState(() => _nosePhoto = null),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Eliminar Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Registrar Ganado',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredioDropdownItem extends StatelessWidget {
  final Predio predio;

  const _PredioDropdownItem({required this.predio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasGps = predio.latitud != null && predio.longitud != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            predio.claveCatastral ?? 'Sin clave catastral',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: cs.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (predio.superficieTotal != null) ...[
                Icon(
                  Icons.straighten_rounded,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  '${predio.superficieTotal!.toStringAsFixed(1)} ha',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
              ],
              if (hasGps) ...[
                Icon(
                  Icons.location_on_rounded,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${predio.latitud!.toStringAsFixed(4)}, '
                    '${predio.longitud!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                Text(
                  'Sin coordenadas GPS',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
