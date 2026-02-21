import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:union_ganadera_app/screens/auth/signup_screen.dart';
import 'package:union_ganadera_app/screens/home/home_screen.dart';
import 'package:union_ganadera_app/screens/ocr/ocr_test_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _curpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _saveCredentials = false;
  final _storage = const FlutterSecureStorage();

  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _initializeAndLoadCredentials();
  }

  Future<void> _initializeAndLoadCredentials() async {
    await _apiClient.initialize();
    await _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedCurp = await _storage.read(key: 'saved_curp');
    final savedPassword = await _storage.read(key: 'saved_password');
    if (savedCurp != null && savedPassword != null) {
      setState(() {
        _curpController.text = savedCurp;
        _passwordController.text = savedPassword;
        _saveCredentials = true;
      });
    }
  }

  @override
  void dispose() {
    _curpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final curp = _curpController.text.trim().toUpperCase();
      await _authService.login(curp, _passwordController.text);

      // Save credentials if enabled
      if (_saveCredentials) {
        await _storage.write(key: 'saved_curp', value: curp);
        await _storage.write(
          key: 'saved_password',
          value: _passwordController.text,
        );
      } else {
        await _storage.delete(key: 'saved_curp');
        await _storage.delete(key: 'saved_password');
      }

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Icon(Icons.pets, size: 80, color: Colors.green.shade700),
                const SizedBox(height: 24),
                Text(
                  'Unión Ganadera',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa a tu cuenta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _curpController,
                  decoration: const InputDecoration(
                    labelText: 'CURP',
                    hintText: 'Ingresa tu CURP',
                    prefixIcon: Icon(Icons.person),
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
                    if (value == null || value.isEmpty) {
                      return 'El CURP es requerido';
                    }
                    if (value.length != 18) {
                      return 'El CURP debe tener 18 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Recordar credenciales'),
                  value: _saveCredentials,
                  onChanged:
                      (value) => setState(() => _saveCredentials = value),
                  activeColor: Colors.green.shade700,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OcrTestScreen()),
                    );
                  },
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Prueba OCR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
