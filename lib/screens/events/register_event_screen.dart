import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/evento.dart';
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
  List<EnfermedadEvento> _enfermedadEventos = [];
  EnfermedadEvento? _selectedEnfermedad;
  bool _isLoadingEnfermedades = false;

  // Remision fields (single bovino only)
  EnfermedadEvento? _selectedEnfermedadRemision;

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
      // Ignore error
    }
  }

  bool get _isVeterinarian => _currentUser?.rol == 'veterinario';

  Future<void> _loadEnfermedadesForBovino() async {
    if (widget.bovinos.length != 1) return;
    setState(() => _isLoadingEnfermedades = true);
    try {
      final eventos = await _eventoService.getEventosByType<EnfermedadEvento>(
        EventType.enfermedad,
        widget.bovinos.first.id,
      );
      if (mounted) {
        setState(() {
          _enfermedadEventos = eventos;
          _selectedEnfermedad = null;
        });
      }
    } catch (_) {
      // silently ignore
    } finally {
      if (mounted) setState(() => _isLoadingEnfermedades = false);
    }
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alimentoController.dispose();
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
    _compradorCurpController.dispose();
    _vendedorCurpController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    const vetEventTypes = {
      'vacunacion',
      'desparasitacion',
      'laboratorio',
      'enfermedad',
      'tratamiento',
      'remision',
    };
    if (vetEventTypes.contains(_eventType) && _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: no se pudo obtener el usuario actual'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final obs =
          _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim();

      for (final bovino in widget.bovinos) {
        switch (_eventType) {
          case 'peso':
            await _eventoService.createPesoEvent(
              bovinoId: bovino.id,
              pesoNuevo: double.parse(_pesoController.text),
              observaciones: obs,
            );
            break;
          case 'dieta':
            await _eventoService.createDietaEvent(
              bovinoId: bovino.id,
              alimento: _alimentoController.text,
              observaciones: obs,
            );
            break;
          case 'vacunacion':
            await _eventoService.createVacunacionEvent(
              bovinoId: bovino.id,
              veterinarioId: _currentUser!.id,
              tipo: _vacunaTipoController.text,
              lote: _vacunaLoteController.text,
              laboratorio: _vacunaLaboratorioController.text,
              fechaProx:
                  _vacunaFechaProx ??
                  DateTime.now().add(const Duration(days: 30)),
              observaciones: obs,
            );
            break;
          case 'desparasitacion':
            await _eventoService.createDesparasitacionEvent(
              bovinoId: bovino.id,
              veterinarioId: _currentUser!.id,
              medicamento: _medicamentoController.text,
              dosis: _dosisController.text,
              fechaProx:
                  _desparasitacionFechaProx ??
                  DateTime.now().add(const Duration(days: 90)),
              observaciones: obs,
            );
            break;
          case 'laboratorio':
            await _eventoService.createLaboratorioEvent(
              bovinoId: bovino.id,
              veterinarioId: _currentUser!.id,
              tipo: _laboratorioTipoController.text,
              resultado: _resultadoController.text,
              observaciones: obs,
            );
            break;
          case 'enfermedad':
            await _eventoService.createEnfermedadEvent(
              bovinoId: bovino.id,
              veterinarioId: _currentUser!.id,
              tipo: _enfermedadDescController.text,
              observaciones: obs,
            );
            break;
          case 'tratamiento':
            await _eventoService.createTratamientoEvent(
              bovinoId: bovino.id,
              enfermedadId: _selectedEnfermedad?.enfermedadId,
              veterinarioId: _currentUser!.id,
              medicamento: _medicamentoTratController.text,
              dosis: _dosisTratController.text,
              periodo: _tratamientoController.text,
              observaciones: obs,
            );
            break;
          case 'compraventa':
            if (_currentUser == null) {
              throw Exception(
                'No se pudo obtener el usuario actual. Intenta de nuevo.',
              );
            }
            await _eventoService.createCompraventaEvent(
              bovinoId: bovino.id,
              compradorCurp: _compradorCurpController.text.toUpperCase(),
              vendedorCurp: _currentUser!.curp.toUpperCase(),
              observaciones: obs,
            );
            break;
          case 'remision':
            if (widget.bovinos.length != 1) {
              throw Exception(
                'La remisión debe registrarse para un solo bovino a la vez.',
              );
            }
            if (_selectedEnfermedadRemision == null ||
                _selectedEnfermedadRemision!.enfermedadId == null) {
              throw Exception(
                'Debes seleccionar la enfermedad a la que corresponde la remisión.',
              );
            }
            await _eventoService.createRemisionEvent(
              bovinoId: bovino.id,
              enfermedadId: _selectedEnfermedadRemision!.enfermedadId!,
              observaciones: obs,
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
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required DateTime last,
  }) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now(),
    lastDate: last,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ModernAppBar(
        title:
            widget.bovinos.length == 1
                ? 'Registrar Evento'
                : 'Evento · ${widget.bovinos.length} bovinos',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.bovinos.length > 1)
                Card(
                  color: cs.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: cs.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este evento se registrará para '
                            '${widget.bovinos.length} bovinos seleccionados.',
                            style: TextStyle(color: cs.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.bovinos.length > 1) const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  prefixIcon: Icon(Icons.event_rounded),
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
                  if (_isVeterinarian) ...[
                    const DropdownMenuItem(
                      value: 'vacunacion',
                      child: Text('Vacunación'),
                    ),
                    const DropdownMenuItem(
                      value: 'desparasitacion',
                      child: Text('Desparasitación'),
                    ),
                    const DropdownMenuItem(
                      value: 'laboratorio',
                      child: Text('Análisis de Laboratorio'),
                    ),
                    const DropdownMenuItem(
                      value: 'enfermedad',
                      child: Text('Enfermedad'),
                    ),
                    const DropdownMenuItem(
                      value: 'tratamiento',
                      child: Text('Tratamiento'),
                    ),
                    const DropdownMenuItem(
                      value: 'remision',
                      child: Text('Remisión (Alta Médica)'),
                    ),
                  ],
                  const DropdownMenuItem(
                    value: 'compraventa',
                    child: Text('Compra / Venta'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _eventType = value!);
                  if (value == 'tratamiento') _loadEnfermedadesForBovino();
                  if (value == 'remision') _loadEnfermedadesForBovino();
                },
              ),
              const SizedBox(height: 20),

              // ─── Peso ───────────────────────────────────────────────────
              if (_eventType == 'peso') ...[
                TextFormField(
                  controller: _pesoController,
                  decoration: const InputDecoration(
                    labelText: 'Peso Actual (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
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

              // ─── Dieta ──────────────────────────────────────────────────
              if (_eventType == 'dieta') ...[
                TextFormField(
                  controller: _alimentoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Alimento',
                    prefixIcon: Icon(Icons.restaurant_rounded),
                  ),
                  maxLines: 2,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'El tipo de alimento es requerido'
                              : null,
                ),
              ],

              // ─── Vacunación ─────────────────────────────────────────────
              if (_eventType == 'vacunacion') ...[
                TextFormField(
                  controller: _vacunaTipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Vacuna',
                    prefixIcon: Icon(Icons.vaccines_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vacunaLoteController,
                  decoration: const InputDecoration(
                    labelText: 'Lote',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vacunaLaboratorioController,
                  decoration: const InputDecoration(
                    labelText: 'Laboratorio',
                    prefixIcon: Icon(Icons.science_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Próxima Vacunación (opcional)',
                  value: _vacunaFechaProx,
                  onTap: () async {
                    final d = await _pickDate(
                      initial: DateTime.now().add(const Duration(days: 365)),
                      last: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (d != null) setState(() => _vacunaFechaProx = d);
                  },
                ),
              ],

              // ─── Desparasitación ────────────────────────────────────────
              if (_eventType == 'desparasitacion') ...[
                TextFormField(
                  controller: _medicamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento',
                    prefixIcon: Icon(Icons.medication_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosisController,
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    prefixIcon: Icon(Icons.colorize_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Próxima Desparasitación (opcional)',
                  value: _desparasitacionFechaProx,
                  onTap: () async {
                    final d = await _pickDate(
                      initial: DateTime.now().add(const Duration(days: 180)),
                      last: DateTime.now().add(const Duration(days: 1825)),
                    );
                    if (d != null)
                      setState(() => _desparasitacionFechaProx = d);
                  },
                ),
              ],

              // ─── Laboratorio ────────────────────────────────────────────
              if (_eventType == 'laboratorio') ...[
                TextFormField(
                  controller: _laboratorioTipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Análisis',
                    prefixIcon: Icon(Icons.biotech_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _resultadoController,
                  decoration: const InputDecoration(
                    labelText: 'Resultado',
                    prefixIcon: Icon(Icons.assignment_rounded),
                  ),
                  maxLines: 3,
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
              ],

              // ─── Enfermedad ─────────────────────────────────────────────
              if (_eventType == 'enfermedad') ...[
                TextFormField(
                  controller: _enfermedadDescController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la Enfermedad',
                    prefixIcon: Icon(Icons.sick_rounded),
                  ),
                  maxLines: 2,
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tratamientoDescController,
                  decoration: const InputDecoration(
                    labelText: 'Tratamiento Aplicado',
                    prefixIcon: Icon(Icons.healing_rounded),
                  ),
                  maxLines: 2,
                ),
              ],

              // ─── Tratamiento ────────────────────────────────────────────
              if (_eventType == 'tratamiento') ...[
                // Enfermedad link (single bovino only)
                if (widget.bovinos.length == 1) ...[
                  _isLoadingEnfermedades
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : DropdownButtonFormField<EnfermedadEvento?>(
                        value: _selectedEnfermedad,
                        decoration: const InputDecoration(
                          labelText: 'Enfermedad vinculada (opcional)',
                          prefixIcon: Icon(Icons.sick_outlined),
                          helperText:
                              'Vincula este tratamiento a una enfermedad registrada',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin enfermedad vinculada'),
                          ),
                          ..._enfermedadEventos.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.tipo,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) => setState(() => _selectedEnfermedad = val),
                      ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _tratamientoController,
                  decoration: const InputDecoration(
                    labelText: 'Período / Descripción del Tratamiento',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicamentoTratController,
                  decoration: const InputDecoration(
                    labelText: 'Medicamento',
                    prefixIcon: Icon(Icons.medication_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosisTratController,
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    prefixIcon: Icon(Icons.colorize_rounded),
                  ),
                  validator:
                      (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
              ],

              // ─── Remisión ────────────────────────────────────────────────
              if (_eventType == 'remision') ...[
                if (widget.bovinos.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'La remisión debe registrarse individualmente '
                            'por bovino ya que requiere vincular una enfermedad específica.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _isLoadingEnfermedades
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : DropdownButtonFormField<EnfermedadEvento?>(
                        value: _selectedEnfermedadRemision,
                        decoration: const InputDecoration(
                          labelText: 'Enfermedad de la que se da de alta',
                          prefixIcon: Icon(Icons.sick_outlined),
                          helperText:
                              'Selecciona la enfermedad que quedó resuelta',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Seleccionar enfermedad...'),
                          ),
                          ..._enfermedadEventos.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.tipo,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        validator:
                            (val) =>
                                val == null
                                    ? 'Debes seleccionar una enfermedad'
                                    : null,
                        onChanged:
                            (val) => setState(
                              () => _selectedEnfermedadRemision = val,
                            ),
                      ),
                ],
              ],

              // ─── Compraventa ────────────────────────────────────────────
              if (_eventType == 'compraventa') ...[
                // Seller identity — always the current authenticated user
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vendedor (tú)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: cs.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            _currentUser == null
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimaryContainer,
                                  ),
                                )
                                : Text(
                                  _currentUser!.curp,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onPrimaryContainer,
                                    letterSpacing: 1,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: cs.onPrimaryContainer.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _compradorCurpController,
                  decoration: const InputDecoration(
                    labelText: 'CURP del Comprador',
                    prefixIcon: Icon(Icons.person_rounded),
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
                    if (_currentUser != null &&
                        value.toUpperCase() ==
                            _currentUser!.curp.toUpperCase()) {
                      return 'El comprador no puede ser el mismo vendedor';
                    }
                    return null;
                  },
                ),
              ],

              // ─── Observaciones (all events) ─────────────────────────────
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                icon:
                    _isLoading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  widget.bovinos.length == 1
                      ? 'Registrar Evento'
                      : 'Registrar para ${widget.bovinos.length} bovinos',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widget ──────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color:
                value != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
