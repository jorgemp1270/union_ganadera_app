import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/evento_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class RegisterEventScreen extends StatefulWidget {
  final List<Bovino> bovinos;

  const RegisterEventScreen({super.key, required this.bovinos});

  @override
  State<RegisterEventScreen> createState() => _RegisterEventScreenState();
}

class _RegisterEventScreenState extends State<RegisterEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  late final EventoService _eventoService;
  late final AuthService _authService;

  String _eventType = 'peso';
  bool _isLoading = false;
  User? _currentUser;

  // Peso fields
  final _pesoController = TextEditingController();

  // Dieta fields
  final _alimentoController = TextEditingController();

  // Vacunacion fields
  final _veterinarioIdController = TextEditingController();
  final _vacunaTipoController = TextEditingController();
  final _vacunaLoteController = TextEditingController();
  final _vacunaLaboratorioController = TextEditingController();
  DateTime? _vacunaFechaProx;

  // Desparasitacion fields
  final _desparasitacionVetController = TextEditingController();
  final _medicamentoController = TextEditingController();
  final _dosisController = TextEditingController();
  DateTime? _desparasitacionFechaProx;

  // Laboratorio fields
  final _laboratorioVetController = TextEditingController();
  final _laboratorioTipoController = TextEditingController();
  final _resultadoController = TextEditingController();

  // Compraventa fields
  final _compradorCurpController = TextEditingController();
  final _vendedorCurpController = TextEditingController();

  // Observaciones
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventoService = EventoService(_apiClient);
    _authService = AuthService(_apiClient);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _vendedorCurpController.text = user.curp;
      });
    } catch (e) {
      // Ignore error, user can input manually
    }
  }

  bool get _isVeterinarian => _currentUser?.rol == 'veterinario';

  @override
  void dispose() {
    _pesoController.dispose();
    _alimentoController.dispose();
    _veterinarioIdController.dispose();
    _vacunaTipoController.dispose();
    _vacunaLoteController.dispose();
    _vacunaLaboratorioController.dispose();
    _desparasitacionVetController.dispose();
    _medicamentoController.dispose();
    _dosisController.dispose();
    _laboratorioVetController.dispose();
    _laboratorioTipoController.dispose();
    _resultadoController.dispose();
    _compradorCurpController.dispose();
    _vendedorCurpController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (final bovino in widget.bovinos) {
        switch (_eventType) {
          case 'peso':
            await _eventoService.createPesoEvent(
              bovinoId: bovino.id,
              pesoNuevo: double.parse(_pesoController.text),
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
          case 'dieta':
            await _eventoService.createDietaEvent(
              bovinoId: bovino.id,
              alimento: _alimentoController.text,
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
          case 'vacunacion':
            await _eventoService.createVacunacionEvent(
              bovinoId: bovino.id,
              veterinarioId: _veterinarioIdController.text,
              tipo: _vacunaTipoController.text,
              lote: _vacunaLoteController.text,
              laboratorio: _vacunaLaboratorioController.text,
              fechaProx: _vacunaFechaProx!,
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
          case 'desparasitacion':
            await _eventoService.createDesparasitacionEvent(
              bovinoId: bovino.id,
              veterinarioId: _desparasitacionVetController.text,
              medicamento: _medicamentoController.text,
              dosis: _dosisController.text,
              fechaProx: _desparasitacionFechaProx!,
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
          case 'laboratorio':
            await _eventoService.createLaboratorioEvent(
              bovinoId: bovino.id,
              veterinarioId: _laboratorioVetController.text,
              tipo: _laboratorioTipoController.text,
              resultado: _resultadoController.text,
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
          case 'compraventa':
            await _eventoService.createCompraventaEvent(
              bovinoId: bovino.id,
              compradorCurp: _compradorCurpController.text.toUpperCase(),
              vendedorCurp: _vendedorCurpController.text.toUpperCase(),
              observaciones:
                  _observacionesController.text.trim().isEmpty
                      ? null
                      : _observacionesController.text.trim(),
            );
            break;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bovinos.length == 1
                ? 'Evento registrado exitosamente'
                : 'Eventos registrados para ${widget.bovinos.length} bovinos',
          ),
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
      appBar: ModernAppBar(
        title:
            widget.bovinos.length == 1
                ? 'Registrar Evento'
                : 'Evento para ${widget.bovinos.length} bovinos',
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.bovinos.length > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Este evento se registrará para todos los bovinos seleccionados',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'peso',
                    child: Text('Registro de Peso'),
                  ),
                  const DropdownMenuItem(
                    value: 'dieta',
                    child: Text('Cambio de Dieta'),
                  ),
                  // Veterinary events - only show to veterinarians
                  if (_isVeterinarian) ...[
                    const DropdownMenuItem(
                      value: 'vacunacion',
                      child: Text('Vacunaci\u00f3n'),
                    ),
                    const DropdownMenuItem(
                      value: 'desparasitacion',
                      child: Text('Desparasitaci\u00f3n'),
                    ),
                    const DropdownMenuItem(
                      value: 'laboratorio',
                      child: Text('An\u00e1lisis de Laboratorio'),
                    ),
                  ],
                  const DropdownMenuItem(
                    value: 'compraventa',
                    child: Text('Compra/Venta'),
                  ),
                ],
                onChanged: (value) => setState(() => _eventType = value!),
              ),
              const SizedBox(height: 24),
              if (_eventType == 'peso') ...[
                TextFormField(
                  controller: _pesoController,
                  decoration: const InputDecoration(
                    labelText: 'Peso Actual (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El peso es requerido';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
              ],
              if (_eventType == 'dieta') ...[
                TextFormField(
                  controller: _alimentoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Alimento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El tipo de alimento es requerido';
                    }
                    return null;
                  },
                ),
              ],
              if (_eventType == 'vacunacion') ...[
                TextFormField(
                  controller: _veterinarioIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID del Veterinario',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vacunaTipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Vacuna',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vacunaLoteController,
                  decoration: const InputDecoration(
                    labelText: 'Lote',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vacunaLaboratorioController,
                  decoration: const InputDecoration(
                    labelText: 'Laboratorio',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) setState(() => _vacunaFechaProx = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Pr\u00f3xima Vacunaci\u00f3n',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _vacunaFechaProx != null
                          ? '${_vacunaFechaProx!.day}/${_vacunaFechaProx!.month}/${_vacunaFechaProx!.year}'
                          : 'Seleccionar fecha',
                    ),
                  ),
                ),
              ],
              if (_eventType == 'desparasitacion') ...[
                TextFormField(
                  controller: _desparasitacionVetController,
                  decoration: const InputDecoration(
                    labelText: 'ID del Veterinario',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosisController,
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 180),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1825)),
                    );
                    if (date != null)
                      setState(() => _desparasitacionFechaProx = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha Pr\u00f3xima Desparasitaci\u00f3n',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _desparasitacionFechaProx != null
                          ? '${_desparasitacionFechaProx!.day}/${_desparasitacionFechaProx!.month}/${_desparasitacionFechaProx!.year}'
                          : 'Seleccionar fecha',
                    ),
                  ),
                ),
              ],
              if (_eventType == 'laboratorio') ...[
                TextFormField(
                  controller: _laboratorioVetController,
                  decoration: const InputDecoration(
                    labelText: 'ID del Veterinario',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _laboratorioTipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de An\u00e1lisis',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _resultadoController,
                  decoration: const InputDecoration(
                    labelText: 'Resultado',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                ),
              ],
              if (_eventType == 'compraventa') ...[
                TextFormField(
                  controller: _compradorCurpController,
                  decoration: const InputDecoration(
                    labelText: 'CURP del Comprador',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      ),
                    ),
                  ],
                  maxLength: 18,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requerido';
                    if (value!.length != 18) return 'Debe tener 18 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vendedorCurpController,
                  decoration: const InputDecoration(
                    labelText: 'CURP del Vendedor',
                    border: OutlineInputBorder(),
                    helperText: 'Se usa tu CURP guardado por defecto',
                    enabled:
                        false, // Vendedor es siempre el usuario actual, no se puede cambiar
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) => TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      ),
                    ),
                  ],
                  maxLength: 18,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requerido';
                    if (value!.length != 18) return 'Debe tener 18 caracteres';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
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
                          'Registrar Evento',
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
