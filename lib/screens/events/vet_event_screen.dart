import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/services/evento_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class VetEventScreen extends StatefulWidget {
  const VetEventScreen({super.key});

  @override
  State<VetEventScreen> createState() => _VetEventScreenState();
}

class _VetEventScreenState extends State<VetEventScreen> {
  final _searchFormKey = GlobalKey<FormState>();
  final _eventFormKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
  late final EventoService _eventoService;
  late final AuthService _authService;

  final _barcodeController = TextEditingController();
  final _rfidController = TextEditingController();

  Bovino? _foundBovino;
  User? _currentUser;
  bool _isSearching = false;
  bool _isSubmitting = false;

  // Event type and fields
  String _eventType = 'vacunacion';

  // Vacunacion fields
  final _vacunaTipoController = TextEditingController();
  final _vacunaLoteController = TextEditingController();
  final _vacunaLaboratorioController = TextEditingController();
  DateTime? _vacunaFechaProx;

  // Desparasitacion fields
  final _medicamentoController = TextEditingController();
  final _dosisController = TextEditingController();
  DateTime? _desparasitacionFechaProx;

  // Laboratorio fields
  final _laboratorioTipoController = TextEditingController();
  final _resultadoController = TextEditingController();

  // Enfermedad fields
  final _enfermedadDescController = TextEditingController();
  final _tratamientoDescController = TextEditingController();

  // Tratamiento fields
  final _tratamientoController = TextEditingController();
  final _medicamentoTratController = TextEditingController();
  final _dosisTratController = TextEditingController();

  // Observaciones
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _eventoService = EventoService(_apiClient);
    _authService = AuthService(_apiClient);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _rfidController.dispose();
    _vacunaTipoController.dispose();
    _vacunaLoteController.dispose();
    _vacunaLaboratorioController.dispose();
    _medicamentoController.dispose();
    _dosisController.dispose();
    _laboratorioTipoController.dispose();
    _resultadoController.dispose();
    _enfermedadDescController.dispose();
    _tratamientoDescController.dispose();
    _tratamientoController.dispose();
    _medicamentoTratController.dispose();
    _dosisTratController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _searchBovino() async {
    if (!_searchFormKey.currentState!.validate()) {
      return;
    }

    if (_barcodeController.text.isEmpty && _rfidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un código de búsqueda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final bovino = await _bovinoService.searchBovino(
        areteBarcode:
            _barcodeController.text.trim().isNotEmpty
                ? _barcodeController.text.trim()
                : null,
        areteRfid:
            _rfidController.text.trim().isNotEmpty
                ? _rfidController.text.trim()
                : null,
      );

      setState(() => _foundBovino = bovino);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bovino encontrado: ${bovino.nombre ?? bovino.id}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Escanear Código de Barras'),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              body: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    setState(() {
                      _barcodeController.text = barcodes.first.rawValue!;
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
      ),
    );
  }

  Future<void> _submitEvent() async {
    if (!_eventFormKey.currentState!.validate()) {
      return;
    }

    if (_foundBovino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes buscar un bovino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: no se pudo obtener el usuario actual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      switch (_eventType) {
        case 'vacunacion':
          await _eventoService.createVacunacionEvent(
            bovinoId: _foundBovino!.id,
            veterinarioId: _currentUser!.id,
            tipo: _vacunaTipoController.text,
            lote: _vacunaLoteController.text,
            laboratorio: _vacunaLaboratorioController.text,
            fechaProx:
                _vacunaFechaProx ??
                DateTime.now().add(const Duration(days: 30)),
            observaciones: _observacionesController.text,
          );
          break;
        case 'desparasitacion':
          await _eventoService.createDesparasitacionEvent(
            bovinoId: _foundBovino!.id,
            veterinarioId: _currentUser!.id,
            medicamento: _medicamentoController.text,
            dosis: _dosisController.text,
            fechaProx:
                _desparasitacionFechaProx ??
                DateTime.now().add(const Duration(days: 90)),
            observaciones: _observacionesController.text,
          );
          break;
        case 'laboratorio':
          await _eventoService.createLaboratorioEvent(
            bovinoId: _foundBovino!.id,
            veterinarioId: _currentUser!.id,
            tipo: _laboratorioTipoController.text,
            resultado: _resultadoController.text,
            observaciones: _observacionesController.text,
          );
          break;
        case 'enfermedad':
          await _eventoService.createEnfermedadEvent(
            bovinoId: _foundBovino!.id,
            veterinarioId: _currentUser!.id,
            tipo: _enfermedadDescController.text,
            observaciones: _observacionesController.text,
          );
          break;
        case 'tratamiento':
          // For tratamiento, we need an enfermedad_id
          // This is simplified - in production you'd select from existing enfermedades
          await _eventoService.createTratamientoEvent(
            bovinoId: _foundBovino!.id,
            enfermedadId: 'placeholder', // TODO: implement enfermedad selection
            veterinarioId: _currentUser!.id,
            medicamento: _medicamentoTratController.text,
            dosis: _dosisTratController.text,
            periodo: _tratamientoController.text,
            observaciones: _observacionesController.text,
          );
          break;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _foundBovino = null;
        _barcodeController.clear();
        _rfidController.clear();
        _vacunaTipoController.clear();
        _vacunaLoteController.clear();
        _vacunaLaboratorioController.clear();
        _vacunaFechaProx = null;
        _medicamentoController.clear();
        _dosisController.clear();
        _desparasitacionFechaProx = null;
        _laboratorioTipoController.clear();
        _resultadoController.clear();
        _enfermedadDescController.clear();
        _tratamientoDescController.clear();
        _tratamientoController.clear();
        _medicamentoTratController.clear();
        _dosisTratController.clear();
        _observacionesController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Eventos Veterinarios',
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchSection(),
              if (_foundBovino != null) ...[
                const SizedBox(height: 24),
                _buildBovinoInfo(),
                const SizedBox(height: 24),
                _buildEventForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _searchFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Buscar Bovino',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Código de Barras',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.camera_alt),
                    color: Colors.blue.shade700,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rfidController,
                decoration: const InputDecoration(
                  labelText: 'RFID (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contactless),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchBovino,
                icon:
                    _isSearching
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBovinoInfo() {
    if (_foundBovino == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Bovino Encontrado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Nombre', _foundBovino!.nombre ?? 'Sin nombre'),
            _buildInfoRow(
              'Código de Barras',
              _foundBovino!.areteBarcode ?? 'N/A',
            ),
            _buildInfoRow('RFID', _foundBovino!.areteRfid ?? 'N/A'),
            _buildInfoRow('Raza', _foundBovino!.razaDominante ?? 'N/A'),
            _buildInfoRow('Sexo', _foundBovino!.sexo ?? 'N/A'),
            _buildInfoRow(
              'Peso Actual',
              _foundBovino!.pesoActual != null
                  ? '${_foundBovino!.pesoActual} kg'
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEventForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _eventFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Registrar Evento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'vacunacion',
                    child: Text('Vacunación'),
                  ),
                  DropdownMenuItem(
                    value: 'desparasitacion',
                    child: Text('Desparasitación'),
                  ),
                  DropdownMenuItem(
                    value: 'laboratorio',
                    child: Text('Análisis de Laboratorio'),
                  ),
                  DropdownMenuItem(
                    value: 'enfermedad',
                    child: Text('Enfermedad'),
                  ),
                  DropdownMenuItem(
                    value: 'tratamiento',
                    child: Text('Tratamiento'),
                  ),
                ],
                onChanged: (value) => setState(() => _eventType = value!),
              ),
              const SizedBox(height: 16),
              ..._buildEventTypeFields(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Registrar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventTypeFields() {
    switch (_eventType) {
      case 'vacunacion':
        return [
          TextFormField(
            controller: _vacunaTipoController,
            decoration: const InputDecoration(
              labelText: 'Tipo de Vacuna',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vacunaLoteController,
            decoration: const InputDecoration(
              labelText: 'Lote',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vacunaLaboratorioController,
            decoration: const InputDecoration(
              labelText: 'Laboratorio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _vacunaFechaProx = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Próxima Vacunación',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _vacunaFechaProx == null
                    ? 'Seleccionar fecha (opcional)'
                    : '${_vacunaFechaProx!.day}/${_vacunaFechaProx!.month}/${_vacunaFechaProx!.year}',
              ),
            ),
          ),
        ];

      case 'desparasitacion':
        return [
          TextFormField(
            controller: _medicamentoController,
            decoration: const InputDecoration(
              labelText: 'Medicamento',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dosisController,
            decoration: const InputDecoration(
              labelText: 'Dosis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 90)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _desparasitacionFechaProx = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Próxima Desparasitación',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _desparasitacionFechaProx == null
                    ? 'Seleccionar fecha (opcional)'
                    : '${_desparasitacionFechaProx!.day}/${_desparasitacionFechaProx!.month}/${_desparasitacionFechaProx!.year}',
              ),
            ),
          ),
        ];

      case 'laboratorio':
        return [
          TextFormField(
            controller: _laboratorioTipoController,
            decoration: const InputDecoration(
              labelText: 'Tipo de Análisis',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _resultadoController,
            decoration: const InputDecoration(
              labelText: 'Resultado',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ];

      case 'enfermedad':
        return [
          TextFormField(
            controller: _enfermedadDescController,
            decoration: const InputDecoration(
              labelText: 'Descripción de la Enfermedad',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tratamientoDescController,
            decoration: const InputDecoration(
              labelText: 'Tratamiento Aplicado',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ];

      case 'tratamiento':
        return [
          TextFormField(
            controller: _tratamientoController,
            decoration: const InputDecoration(
              labelText: 'Tratamiento',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicamentoTratController,
            decoration: const InputDecoration(
              labelText: 'Medicamento',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dosisTratController,
            decoration: const InputDecoration(
              labelText: 'Dosis',
              border: OutlineInputBorder(),
            ),
          ),
        ];

      default:
        return [];
    }
  }
}
