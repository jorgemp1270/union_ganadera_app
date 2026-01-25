import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';

class RegisterCattleScreen extends StatefulWidget {
  const RegisterCattleScreen({super.key});

  @override
  State<RegisterCattleScreen> createState() => _RegisterCattleScreenState();
}

class _RegisterCattleScreenState extends State<RegisterCattleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areteBarcodeController = TextEditingController();
  final _areteRfidController = TextEditingController();
  final _razaDominanteController = TextEditingController();
  final _pesoNacController = TextEditingController();
  final _pesoActualController = TextEditingController();
  final _propositoController = TextEditingController();

  DateTime? _fechaNacimiento;
  String _sexo = 'M';
  bool _isLoading = false;
  bool _nfcAvailable = false;

  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _areteBarcodeController.dispose();
    _areteRfidController.dispose();
    _razaDominanteController.dispose();
    _pesoNacController.dispose();
    _pesoActualController.dispose();
    _propositoController.dispose();
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
        builder: (context) => Scaffold(
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
              _areteRfidController.text = tag.data['nfca']?['identifier']?.toString() ?? '';
            });
          }
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al leer NFC: $e')),
      );
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bovino = Bovino(
        id: '',
        usuarioId: '',
        areteBarcode: _areteBarcodeController.text.trim().isEmpty
            ? null
            : _areteBarcodeController.text.trim(),
        areteRfid: _areteRfidController.text.trim().isEmpty
            ? null
            : _areteRfidController.text.trim(),
        razaDominante: _razaDominanteController.text.trim().isEmpty
            ? null
            : _razaDominanteController.text.trim(),
        fechaNac: _fechaNacimiento,
        sexo: _sexo,
        pesoNac: _pesoNacController.text.trim().isEmpty
            ? null
            : double.tryParse(_pesoNacController.text.trim()),
        pesoActual: _pesoActualController.text.trim().isEmpty
            ? null
            : double.tryParse(_pesoActualController.text.trim()),
        proposito: _propositoController.text.trim().isEmpty
            ? null
            : _propositoController.text.trim(),
        status: 'activo',
      );

      await _bovinoService.createBovino(bovino);

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
      appBar: AppBar(
        title: const Text('Registrar Ganado'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  suffixIcon: _nfcAvailable
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _razaDominanteController,
                decoration: const InputDecoration(
                  labelText: 'Raza Dominante',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _propositoController,
                decoration: const InputDecoration(
                  labelText: 'Propósito (Engorda, Reproducción, etc.)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
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
                child: _isLoading
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
