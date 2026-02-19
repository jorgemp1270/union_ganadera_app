import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);
    try {
      final savedIp = await _storage.read(key: 'api_ip');
      final savedPort = await _storage.read(key: 'api_port');

      setState(() {
        _ipController.text = savedIp ?? '10.0.2.2';
        _portController.text = savedPort ?? '8000';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _ipController.text = '10.0.2.2';
        _portController.text = '8000';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _storage.write(key: 'api_ip', value: _ipController.text);
      await _storage.write(key: 'api_port', value: _portController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuración guardada. Reinicia la app para aplicar cambios.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _ipController.text = '10.0.2.2';
      _portController.text = '8000';
    });

    await _storage.delete(key: 'api_ip');
    await _storage.delete(key: 'api_port');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración restablecida a valores predeterminados'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(title: 'Configuración de API'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning card
                      Card(
                        color: cs.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: cs.onTertiaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Solo para pruebas. Cambia la IP y puerto del servidor API.',
                                  style: TextStyle(
                                    color: cs.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección IP',
                          hintText: '10.0.2.2 o localhost',
                          prefixIcon: Icon(Icons.computer_rounded),
                          helperText:
                              'Android emulador: 10.0.2.2  ·  iOS: localhost o IP de PC',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La IP es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Puerto',
                          hintText: '8000',
                          prefixIcon: Icon(Icons.settings_ethernet_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El puerto es requerido';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port < 1 || port > 65535) {
                            return 'Puerto inválido (1-65535)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Live URL preview
                      Card(
                        color: cs.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'URL resultante',
                                style: TextStyle(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                'http://${_ipController.text}:${_portController.text}',
                                style: TextStyle(
                                  color: cs.onSecondaryContainer,
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar Configuración'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _resetToDefault,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Restablecer Predeterminados'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Info card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: cs.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Guía de conexión',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '• Emulador Android: usa 10.0.2.2\n'
                                '• Simulador iOS: usa localhost\n'
                                '• Dispositivo físico: IP de tu PC en la red local\n'
                                '• Después de guardar, reinicia la app completamente',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  height: 1.6,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }
}
