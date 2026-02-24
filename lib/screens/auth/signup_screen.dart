import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/screens/home/home_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/utils/curp_validator.dart';
import 'package:union_ganadera_app/utils/file_picker_sheet.dart';
import 'package:union_ganadera_app/utils/ocr_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step indices
// ─────────────────────────────────────────────────────────────────────────────
// Ganadero:    0=INE Frente  1=INE Reverso  2=Contraseña
// Veterinario: 0=INE Frente  1=INE Reverso  2=Cédula  3=Contraseña

class SignupScreen extends StatefulWidget {
  final bool embedded;

  const SignupScreen({super.key, this.embedded = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _apellidoPCtrl = TextEditingController();
  final _apellidoMCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  final _claveElectorCtrl = TextEditingController();
  final _idmexCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _cedulaNumCtrl = TextEditingController();

  // ── Form keys (one per step) ─────────────────────────────────────────────
  final _frontFormKey = GlobalKey<FormState>();
  final _backFormKey = GlobalKey<FormState>();
  final _cedulaFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // ── State ────────────────────────────────────────────────────────────────────
  int _currentStep = 0;
  String _userType = 'ganadero';
  String _sexo = 'M';
  DateTime? _fechaNacimiento;

  File? _ineFrontPhoto;
  File? _ineBackPhoto;
  File? _cedulaFile;

  bool _isScanning = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;
  late final FileService _fileService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _fileService = FileService(_apiClient);
    _apiClient.initialize();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPCtrl.dispose();
    _apellidoMCtrl.dispose();
    _curpCtrl.dispose();
    _claveElectorCtrl.dispose();
    _idmexCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cedulaNumCtrl.dispose();
    super.dispose();
  }

  // ── Step helpers ─────────────────────────────────────────────────────────────

  int get _totalSteps => _userType == 'veterinario' ? 4 : 3;

  List<String> get _stepLabels {
    final base = ['INE Frente', 'INE Reverso'];
    if (_userType == 'veterinario') base.add('Cédula');
    base.add('Contraseña');
    return base;
  }

  // ── OCR scanning ────────────────────────────────────────────────────────────

  Future<void> _scanIneFront() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo == null) return;

    setState(() {
      _ineFrontPhoto = File(photo.path);
      _isScanning = true;
    });

    try {
      final data = await OcrUtil.scanIneFront(_ineFrontPhoto!);
      setState(() {
        if (data.apellidoPaterno != null) {
          _apellidoPCtrl.text = _toTitleCase(data.apellidoPaterno!);
        }
        if (data.apellidoMaterno != null) {
          _apellidoMCtrl.text = _toTitleCase(data.apellidoMaterno!);
        }
        if (data.nombre != null) {
          _nombreCtrl.text = _toTitleCase(data.nombre!);
        }
        if (data.claveElector != null) {
          _claveElectorCtrl.text = data.claveElector!;
        }
        if (data.curp != null) {
          _curpCtrl.text = data.curp!;
        }
        if (data.fechaNacimiento != null) {
          try {
            _fechaNacimiento = DateFormat(
              'dd/MM/yyyy',
            ).parse(data.fechaNacimiento!);
          } catch (_) {}
        }
        // INE uses H/M; API expects M/F/X — map accordingly
        if (data.sexo != null) {
          _sexo = switch (data.sexo!.toUpperCase()) {
            'H' => 'M',
            'M' => 'F',
            _ => 'X',
          };
        }
      });
    } catch (e) {
      debugPrint('OCR frente error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _scanIneBack() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo == null) return;

    setState(() {
      _ineBackPhoto = File(photo.path);
      _isScanning = true;
    });

    try {
      final data = await OcrUtil.scanIneBack(_ineBackPhoto!);
      if (data.idmex != null) {
        setState(() => _idmexCtrl.text = data.idmex!);
      }
    } catch (e) {
      debugPrint('OCR reverso error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _nextStep() {
    bool valid = true;
    if (_currentStep == 0)
      valid = _frontFormKey.currentState?.validate() ?? false;
    if (_currentStep == 1)
      valid = _backFormKey.currentState?.validate() ?? false;
    if (_userType == 'veterinario' && _currentStep == 2) {
      valid = _cedulaFormKey.currentState?.validate() ?? false;
    }

    if (_currentStep == 0 && _ineFrontPhoto == null) {
      _showError('Debes tomar la foto del frente de tu INE');
      return;
    }
    if (_currentStep == 1 && _ineBackPhoto == null) {
      _showError('Debes tomar la foto del reverso de tu INE');
      return;
    }
    if (_userType == 'veterinario' &&
        _currentStep == 2 &&
        _cedulaFile == null) {
      _showError('Debes subir tu cédula profesional');
      return;
    }

    if (!valid) return;
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── Signup submission ────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    if (_fechaNacimiento == null) {
      _showError('La fecha de nacimiento es requerida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Register
      if (_userType == 'veterinario') {
        try {
          await _authService.signupVeterinarian(
            VeterinarianRegistration(
              curp: _curpCtrl.text.trim(),
              contrasena: _passwordCtrl.text,
              nombre: _nombreCtrl.text.trim(),
              apellidoP: _apellidoPCtrl.text.trim(),
              apellidoM: _apellidoMCtrl.text.trim(),
              sexo: _sexo,
              fechaNac: _fechaNacimiento!,
              claveElector: _claveElectorCtrl.text.trim(),
              idmex: _idmexCtrl.text.trim(),
              cedula: _cedulaNumCtrl.text.trim(),
            ),
            _cedulaFile!,
          );
        } catch (_) {
          // cedula file processing failed on server — proceed anyway,
          // cedula will be re-uploaded as a non-fatal doc in _tryUploadDocs
        }
      } else {
        await _authService.signup(
          UserRegistration(
            curp: _curpCtrl.text.trim(),
            contrasena: _passwordCtrl.text,
            nombre: _nombreCtrl.text.trim(),
            apellidoP: _apellidoPCtrl.text.trim(),
            apellidoM: _apellidoMCtrl.text.trim(),
            sexo: _sexo,
            fechaNac: _fechaNacimiento!,
            claveElector: _claveElectorCtrl.text.trim(),
            idmex: _idmexCtrl.text.trim(),
          ),
        );
      }

      // 2. Login — must succeed before uploads
      await _authService.login(_curpCtrl.text.trim(), _passwordCtrl.text);

      // 3. Upload documents — non-fatal
      await _tryUploadDocs();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _tryUploadDocs() async {
    if (_cedulaFile != null && _userType == 'veterinario') {
      try {
        await _fileService.uploadFile(
          file: _cedulaFile!,
          docType: DocType.cedulaVeterinario,
        );
      } catch (_) {}
    }
    if (_ineFrontPhoto != null) {
      try {
        await _fileService.uploadFile(
          file: _ineFrontPhoto!,
          docType: DocType.identificacionFrente,
        );
      } catch (_) {}
    }
    if (_ineBackPhoto != null) {
      try {
        await _fileService.uploadFile(
          file: _ineBackPhoto!,
          docType: DocType.identificacionReverso,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Algunos documentos no se subieron. Puedes subirlos desde tu perfil.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');

  String? _validateCurp(String? value) {
    if (value == null || value.isEmpty) return 'El CURP es requerido';
    if (!CurpValidator.validarFormatoCURP(value)) {
      return 'Formato de CURP inválido';
    }
    if (_fechaNacimiento != null &&
        _nombreCtrl.text.isNotEmpty &&
        _apellidoPCtrl.text.isNotEmpty) {
      final ok = CurpValidator.validarCURP(
        curp: value,
        nombre: _nombreCtrl.text,
        apellidoPaterno: _apellidoPCtrl.text,
        apellidoMaterno: _apellidoMCtrl.text,
        dia: _fechaNacimiento!.day,
        mes: _fechaNacimiento!.month,
        anio: _fechaNacimiento!.year,
      );
      if (!ok)
        return 'El CURP no coincide con los datos (nombre, apellidos, fecha de nacimiento)';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _StepIndicator(
          total: _totalSteps,
          current: _currentStep,
          labels: _stepLabels,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _buildCurrentStep(),
          ),
        ),
        _buildNavBar(),
      ],
    );

    if (widget.embedded) {
      return SafeArea(child: body);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) return _buildFronteStep();
    if (_currentStep == 1) return _buildReversoStep();
    if (_userType == 'veterinario' && _currentStep == 2) {
      return _buildCedulaStep();
    }
    return _buildPasswordStep();
  }

  Widget _buildNavBar() {
    final isLast = _currentStep == _totalSteps - 1;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _prevStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Atrás'),
            ),
          const Spacer(),
          if (!isLast)
            FilledButton.icon(
              onPressed: _isScanning ? null : _nextStep,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Siguiente'),
            ),
          if (isLast)
            FilledButton.icon(
              onPressed: _isLoading ? null : _handleSignup,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.check_rounded),
              label: const Text('Crear cuenta'),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 0 — INE Frente
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFronteStep() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUserTypeSelector(),
        const SizedBox(height: 20),
        _SectionTitle(
          icon: Icons.credit_card_outlined,
          label: 'Frente de tu INE',
        ),
        const SizedBox(height: 4),
        Text(
          'Toma una foto del frente de tu credencial. '
          'Los datos se detectarán automáticamente.',
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        _PhotoCapture(
          imageFile: _ineFrontPhoto,
          isScanning: _isScanning,
          onCapture: _scanIneFront,
          label: 'Tomar foto del frente',
        ),
        const SizedBox(height: 20),
        Form(
          key: _frontFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(
                'Verifica, corrige e ingresa los datos requeridos si es necesario.',
                icon: Icons.info_outline_rounded,
                color: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoPCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apellido paterno',
                ),
                textCapitalization: TextCapitalization.words,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellidoMCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apellido materno',
                ),
                textCapitalization: TextCapitalization.words,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre(s)'),
                textCapitalization: TextCapitalization.words,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    controller: TextEditingController(
                      text:
                          _fechaNacimiento == null
                              ? ''
                              : DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaNacimiento!),
                    ),
                    validator:
                        (_) => _fechaNacimiento == null ? 'Requerida' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: const ['M', 'F', 'X'].contains(_sexo) ? _sexo : 'M',
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Hombre (H)')),
                  DropdownMenuItem(value: 'F', child: Text('Mujer (M)')),
                  DropdownMenuItem(value: 'X', child: Text('Otro (X)')),
                ],
                onChanged: (v) => setState(() => _sexo = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _curpCtrl,
                decoration: const InputDecoration(labelText: 'CURP'),
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  TextInputFormatter.withFunction(
                    (o, n) => n.copyWith(text: n.text.toUpperCase()),
                  ),
                ],
                validator: _validateCurp,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _claveElectorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clave de elector',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerida' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — INE Reverso
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReversoStep() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.flip_to_back_outlined,
          label: 'Reverso de tu INE',
        ),
        const SizedBox(height: 4),
        Text(
          'Toma una foto del reverso de tu credencial. '
          'El código IDMEX se detectará automáticamente.',
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        _PhotoCapture(
          imageFile: _ineBackPhoto,
          isScanning: _isScanning,
          onCapture: _scanIneBack,
          label: 'Tomar foto del reverso',
        ),
        const SizedBox(height: 20),
        Form(
          key: _backFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(
                'Verifica el código IDMEX de 10 dígitos detectado. Si no se detectó, ingrésalo manualmente.',
                icon: Icons.info_outline_rounded,
                color: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idmexCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código IDMEX (10 dígitos)',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 (vet only) — Cédula
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCedulaStep() {
    final cs = Theme.of(context).colorScheme;
    final isImage =
        _cedulaFile != null &&
        (_cedulaFile!.path.toLowerCase().endsWith('.jpg') ||
            _cedulaFile!.path.toLowerCase().endsWith('.jpeg') ||
            _cedulaFile!.path.toLowerCase().endsWith('.png'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.medical_services_outlined,
          label: 'Cédula Profesional',
        ),
        const SizedBox(height: 4),
        Text(
          'Ingresa tu número de cédula y sube una foto o archivo del documento.',
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Form(
          key: _cedulaFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cedulaNumCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número de cédula profesional',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Ej: 12345678',
                ),
                keyboardType: TextInputType.number,
                maxLength: 50,
                validator:
                    (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final file = await FilePickerSheet.show(
                    context,
                    title: 'Cédula profesional',
                    includeFilePicker: true,
                  );
                  if (file != null) setState(() => _cedulaFile = file);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        _cedulaFile != null
                            ? cs.primaryContainer.withOpacity(0.3)
                            : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _cedulaFile != null ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cedulaFile != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        color:
                            _cedulaFile != null
                                ? cs.primary
                                : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _cedulaFile != null
                              ? _cedulaFile!.path.split(RegExp(r'[\\/]')).last
                              : 'Subir foto / archivo de cédula',
                          style: TextStyle(
                            color:
                                _cedulaFile != null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isImage)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _cedulaFile!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LAST STEP — Password
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPasswordStep() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(icon: Icons.lock_outlined, label: 'Crea tu contraseña'),
        const SizedBox(height: 4),
        Text(
          'Elige una contraseña segura para tu cuenta.',
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),
                obscureText: _obscurePassword,
                maxLength: 72,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerida';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordCtrl,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed:
                        () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                maxLength: 72,
                validator: (v) {
                  if (v != _passwordCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final cs = Theme.of(context).colorScheme;
    final nombre =
        '${_apellidoPCtrl.text} ${_apellidoMCtrl.text} ${_nombreCtrl.text}'
            .trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de tu registro',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Nombre', value: nombre),
          _SummaryRow(label: 'CURP', value: _curpCtrl.text),
          _SummaryRow(label: 'Clave elector', value: _claveElectorCtrl.text),
          _SummaryRow(label: 'IDMEX', value: _idmexCtrl.text),
          _SummaryRow(
            label: 'Tipo',
            value: _userType == 'veterinario' ? 'Veterinario' : 'Ganadero',
          ),
          if (_userType == 'veterinario')
            _SummaryRow(label: 'Cédula', value: _cedulaNumCtrl.text),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'ganadero',
          label: Text('Ganadero'),
          icon: Icon(Icons.agriculture_rounded),
        ),
        ButtonSegment(
          value: 'veterinario',
          label: Text('Veterinario'),
          icon: Icon(Icons.medical_services_outlined),
        ),
      ],
      selected: {_userType},
      onSelectionChanged: (s) => setState(() => _userType = s.first),
    );
  }

  Widget _buildInfoBanner(
    String text, {
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int total;
  final int current;
  final List<String> labels;

  const _StepIndicator({
    required this.total,
    required this.current,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final done = stepIdx < current;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? cs.primary : cs.outlineVariant,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final done = stepIdx < current;
          final active = stepIdx == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done
                          ? cs.primary
                          : active
                          ? cs.primaryContainer
                          : cs.surfaceContainerHigh,
                  border: Border.all(
                    color: active || done ? cs.primary : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child:
                      done
                          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                          : Text(
                            '${stepIdx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  active
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIdx],
                style: TextStyle(
                  fontSize: 10,
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PhotoCapture extends StatelessWidget {
  final File? imageFile;
  final bool isScanning;
  final VoidCallback onCapture;
  final String label;

  const _PhotoCapture({
    required this.imageFile,
    required this.isScanning,
    required this.onCapture,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isScanning ? null : onCapture,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: imageFile != null ? cs.primary : cs.outlineVariant,
            width: imageFile != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child:
            isScanning
                ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Analizando imagen…'),
                    ],
                  ),
                )
                : imageFile != null
                ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FilledButton.icon(
                        onPressed: onCapture,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retomar'),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
