import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/screens/auth/auth_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/services/file_service.dart';
import 'package:union_ganadera_app/utils/curp_validator.dart';

class SignupScreen extends StatefulWidget {
  final bool embedded;

  const SignupScreen({super.key, this.embedded = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoPController = TextEditingController();
  final _apellidoMController = TextEditingController();
  final _curpController = TextEditingController();
  final _claveElectorController = TextEditingController();
  final _idmexController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _sexo = 'M';
  File? _inePhoto;
  File? _comprobanteDomicilioPhoto;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;
  late final FileService _fileService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _fileService = FileService(_apiClient);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPController.dispose();
    _apellidoMController.dispose();
    _curpController.dispose();
    _claveElectorController.dispose();
    _idmexController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isINE) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (isINE) {
          _inePhoto = File(image.path);
        } else {
          _comprobanteDomicilioPhoto = File(image.path);
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );

    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  String? _validateCURP(String? value) {
    if (value == null || value.isEmpty) {
      return 'El CURP es requerido';
    }

    if (!CurpValidator.validarFormatoCURP(value)) {
      return 'Formato de CURP inválido';
    }

    if (_fechaNacimiento != null) {
      final isValid = CurpValidator.validarCURP(
        curp: value,
        nombre: _nombreController.text,
        apellidoPaterno: _apellidoPController.text,
        apellidoMaterno: _apellidoMController.text,
        dia: _fechaNacimiento!.day,
        mes: _fechaNacimiento!.month,
        anio: _fechaNacimiento!.year,
      );

      if (!isValid) {
        return 'El CURP no coincide con los datos proporcionados';
      }
    }

    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona tu fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_inePhoto == null || _comprobanteDomicilioPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes tomar fotos de tu INE y comprobante de domicilio',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Register user
      final registration = UserRegistration(
        curp: _curpController.text.trim(),
        contrasena: _passwordController.text,
        nombre: _nombreController.text.trim(),
        apellidoP: _apellidoPController.text.trim(),
        apellidoM: _apellidoMController.text.trim(),
        sexo: _sexo,
        fechaNac: _fechaNacimiento!,
        claveElector: _claveElectorController.text.trim(),
        idmex: _idmexController.text.trim(),
      );

      await _authService.signup(registration);

      // 2. Login to get token
      await _authService.login(
        _curpController.text.trim(),
        _passwordController.text,
      );

      // 3. Upload documents
      await _fileService.uploadFile(
        file: _inePhoto!,
        docType: DocType.identificacion,
      );

      await _fileService.uploadFile(
        file: _comprobanteDomicilioPhoto!,
        docType: DocType.comprobanteDomicilio,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Tus documentos serán revisados.'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.embedded) {
        // If embedded in tab view, just pop
        Navigator.of(context).pop();
      } else {
        // If standalone, navigate to auth screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Embedded in tab view, no AppBar
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildForm(),
        ),
      );
    }

    // Standalone screen with AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ganadero'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IMPORTANTE: Los datos deben coincidir exactamente con tu INE',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre(s)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator:
                (value) =>
                    value?.isEmpty ?? true ? 'El nombre es requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apellidoPController,
            decoration: const InputDecoration(
              labelText: 'Apellido Paterno',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator:
                (value) =>
                    value?.isEmpty ?? true
                        ? 'El apellido paterno es requerido'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apellidoMController,
            decoration: const InputDecoration(
              labelText: 'Apellido Materno',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator:
                (value) =>
                    value?.isEmpty ?? true
                        ? 'El apellido materno es requerido'
                        : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sexo,
            decoration: const InputDecoration(
              labelText: 'Sexo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculino')),
              DropdownMenuItem(value: 'F', child: Text('Femenino')),
              DropdownMenuItem(value: 'X', child: Text('Otro')),
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
                    ? 'Selecciona tu fecha de nacimiento'
                    : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _curpController,
            decoration: const InputDecoration(
              labelText: 'CURP',
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
            validator: _validateCURP,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _claveElectorController,
            decoration: const InputDecoration(
              labelText: 'Clave de Elector (INE)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator:
                (value) =>
                    value?.isEmpty ?? true
                        ? 'La clave de elector es requerida'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _idmexController,
            decoration: const InputDecoration(
              labelText: 'Número de ID (INE)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator:
                (value) => value?.isEmpty ?? true ? 'El ID es requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            maxLength: 72,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña es requerida';
              }
              if (value.length < 8) {
                return 'Mínimo 8 caracteres';
              }
              if (value.length > 72) {
                return 'Máximo 72 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            maxLength: 72,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Documentos Requeridos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickImage(true),
            icon: Icon(_inePhoto == null ? Icons.camera_alt : Icons.check),
            label: Text(
              _inePhoto == null ? 'Tomar foto de INE' : 'Foto de INE capturada',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: _inePhoto == null ? Colors.blue : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(false),
            icon: Icon(
              _comprobanteDomicilioPhoto == null
                  ? Icons.camera_alt
                  : Icons.check,
            ),
            label: Text(
              _comprobanteDomicilioPhoto == null
                  ? 'Tomar foto de Comprobante de Domicilio'
                  : 'Comprobante capturado',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor:
                  _comprobanteDomicilioPhoto == null
                      ? Colors.blue
                      : Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
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
                    : const Text('Registrarse', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
