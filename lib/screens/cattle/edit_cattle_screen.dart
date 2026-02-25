import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class EditCattleScreen extends StatefulWidget {
  final Bovino bovino;

  const EditCattleScreen({super.key, required this.bovino});

  @override
  State<EditCattleScreen> createState() => _EditCattleScreenState();
}

class _EditCattleScreenState extends State<EditCattleScreen> {
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
  List<Bovino> _allBovinos = [];
  String? _selectedMadreId;
  String? _selectedPadreId;
  bool _isLoadingBovinos = false;

  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
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
    _loadBovinoData();
    _loadBovinos();
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

  void _loadBovinoData() {
    _nombreController.text = widget.bovino.nombre ?? '';
    _areteBarcodeController.text = widget.bovino.areteBarcode ?? '';
    _areteRfidController.text = widget.bovino.areteRfid ?? '';
    _pesoNacController.text = widget.bovino.pesoNac?.toString() ?? '';
    _pesoActualController.text = widget.bovino.pesoActual?.toString() ?? '';
    _fechaNacimiento = widget.bovino.fechaNac;
    _sexo = widget.bovino.sexo ?? 'M';
    _selectedMadreId = widget.bovino.madreId;
    _selectedPadreId = widget.bovino.padreId;

    // Set raza
    if (widget.bovino.razaDominante != null) {
      if (_razas.contains(widget.bovino.razaDominante)) {
        _selectedRaza = widget.bovino.razaDominante;
      } else {
        _selectedRaza = 'Otro';
        _razaDominanteController.text = widget.bovino.razaDominante!;
        _showOtherRaza = true;
      }
    }

    // Set proposito
    if (widget.bovino.proposito != null) {
      if (_propositos.contains(widget.bovino.proposito)) {
        _selectedProposito = widget.bovino.proposito;
      } else {
        _selectedProposito = 'Otro';
        _propositoController.text = widget.bovino.proposito!;
        _showOtherProposito = true;
      }
    }

    // Set status
    if (_estados.contains(widget.bovino.status)) {
      _selectedStatus = widget.bovino.status;
    } else {
      _selectedStatus = 'Otro';
      _statusController.text = widget.bovino.status;
      _showOtherStatus = true;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
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
      String status = widget.bovino.status; // Keep current if not changed
      if (_selectedStatus != null) {
        if (_selectedStatus == 'Otro') {
          status =
              _statusController.text.trim().isEmpty
                  ? widget.bovino.status
                  : _statusController.text.trim();
        } else {
          status = _selectedStatus!;
        }
      }

      final updates = {
        'nombre':
            _nombreController.text.trim().isEmpty
                ? null
                : _nombreController.text.trim(),
        'arete_barcode':
            _areteBarcodeController.text.trim().isEmpty
                ? null
                : _areteBarcodeController.text.trim(),
        'arete_rfid':
            _areteRfidController.text.trim().isEmpty
                ? null
                : _areteRfidController.text.trim(),
        'raza_dominante': razaDominante,
        'fecha_nac': _fechaNacimiento?.toIso8601String().split('T')[0],
        'sexo': _sexo,
        'peso_nac':
            _pesoNacController.text.trim().isEmpty
                ? null
                : double.tryParse(_pesoNacController.text.trim()),
        'peso_actual':
            _pesoActualController.text.trim().isEmpty
                ? null
                : double.tryParse(_pesoActualController.text.trim()),
        'proposito': proposito,
        'status': status,
      }..removeWhere((key, value) => value == null);

      // Always include madre_id / padre_id so they can be cleared
      updates['madre_id'] = _selectedMadreId;
      updates['padre_id'] = _selectedPadreId;

      await _bovinoService.updateBovino(widget.bovino.id, updates);

      // Upload nose photo if selected
      if (_nosePhoto != null) {
        try {
          await _bovinoService.uploadNosePhoto(widget.bovino.id, _nosePhoto!);
        } catch (e) {
          // Show warning but don't fail the update
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bovino actualizado, pero error al subir foto: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bovino actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
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
        title: 'Editar Ganado',
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
                decoration: const InputDecoration(
                  labelText: 'Arete Código de Barras',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areteRfidController,
                decoration: const InputDecoration(
                  labelText: 'Arete RFID/NFC',
                  border: OutlineInputBorder(),
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
                  value:
                      _allBovinos.any((b) => b.id == _selectedMadreId)
                          ? _selectedMadreId
                          : null,
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
                        .where((b) => b.sexo == 'F' && b.id != widget.bovino.id)
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
                  value:
                      _allBovinos.any((b) => b.id == _selectedPadreId)
                          ? _selectedPadreId
                          : null,
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
                        .where((b) => b.sexo == 'M' && b.id != widget.bovino.id)
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
                'Traslado de Predio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para cambiar el predio del animal, registra un evento de traslado.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RegisterEventScreen(
                            bovinos: [widget.bovino],
                            initialEventType: 'traslado',
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Registrar Traslado'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Foto de la Nariz (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Actualizar la foto de la nariz del ganado',
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
                    'Eliminar Foto Nueva',
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
                          'Guardar Cambios',
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
