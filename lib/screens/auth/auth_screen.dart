import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:union_ganadera_app/screens/home/home_screen.dart';
// import 'package:union_ganadera_app/screens/ocr/ocr_test_screen.dart';
import 'package:union_ganadera_app/screens/settings/api_settings_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';
import 'package:union_ganadera_app/screens/auth/signup_screen.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class AuthScreen extends StatefulWidget {
  final int initialTab;

  const AuthScreen({super.key, this.initialTab = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ModernAppBar(
        title: 'MUU-NITOREO',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración de API',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: cs.onPrimary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Iniciar Sesión'),
                  Tab(text: 'Registrarse'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [LoginTab(), SignupTab()],
      ),
    );
  }
}

// Login Tab Widget
class LoginTab extends StatefulWidget {
  const LoginTab({super.key});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
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
    _loadSavedCredentials();
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.agriculture_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa a tu cuenta',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _curpController,
                decoration: const InputDecoration(
                  labelText: 'CURP',
                  hintText: 'Ingresa tu CURP',
                  prefixIcon: Icon(Icons.badge_outlined),
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
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
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
                onChanged: (value) => setState(() => _saveCredentials = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Iniciar Sesión'),
              ),
              // const SizedBox(height: 12),
              // OutlinedButton.icon(
              //   onPressed:
              //       () => Navigator.of(context).push(
              //         MaterialPageRoute(builder: (_) => const OcrTestScreen()),
              //       ),
              //   icon: const Icon(Icons.document_scanner_outlined),
              //   label: const Text('Prueba OCR'),
              //   style: OutlinedButton.styleFrom(
              //     minimumSize: const Size.fromHeight(48),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// Signup Tab Widget
class SignupTab extends StatelessWidget {
  const SignupTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the existing SignupScreen but remove its AppBar
    return const SignupScreen(embedded: true);
  }
}
