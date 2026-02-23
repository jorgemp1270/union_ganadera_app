import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INE data model
// ─────────────────────────────────────────────────────────────────────────────
class IneData {
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? nombre;
  final String? claveElector;
  final String? curp;
  final String? fechaNacimiento;
  final String? sexo;

  const IneData({
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.nombre,
    this.claveElector,
    this.curp,
    this.fechaNacimiento,
    this.sexo,
  });

  Map<String, String?> toMap() => {
    'apellido_paterno': apellidoPaterno,
    'apellido_materno': apellidoMaterno,
    'nombre': nombre,
    'clave_elector': claveElector,
    'curp': curp,
    'fecha_nacimiento': fechaNacimiento,
    'sexo': sexo,
  };

  String toJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}

// ─────────────────────────────────────────────────────────────────────────────
// Parser
// ─────────────────────────────────────────────────────────────────────────────
IneData parseIneText(String rawText) {
  final lines =
      rawText
          .split('\n')
          .map((l) => l.trim().toUpperCase())
          .where((l) => l.isNotEmpty)
          .toList();

  String? ap, am, nombre, claveElector, curp, fechaNac, sexo;

  // Clave elector: 18 alphanumeric uppercase chars
  final claveRe = RegExp(r'[A-ZÑ0-9]{18}');
  // Date dd/mm/yyyy
  final dateRe = RegExp(r'\d{2}/\d{2}/\d{4}');

  // Pre-locate key label indices for bounded CURP search
  final curpLabelIdx = lines.indexWhere(
    (l) => l == 'CURP' || l.startsWith('CURP '),
  );
  final fechaLabelIdx = lines.indexWhere((l) => l.contains('NACIMIENTO'));

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // ── Nombre block: after "NOMBRE" the next 3 lines are AP, AM, nombre ─────
    if (line == 'NOMBRE' && i + 3 < lines.length) {
      ap = _cleanName(lines[i + 1]);
      am = _cleanName(lines[i + 2]);
      nombre = _cleanName(lines[i + 3]);
    }

    // ── Clave de elector ──────────────────────────────────────────────────────
    if (line.contains('CLAVE') && line.contains('ELECTOR')) {
      final match = claveRe.firstMatch(line);
      if (match != null) {
        claveElector = match.group(0);
      } else if (i + 1 < lines.length) {
        final nextMatch = claveRe.firstMatch(lines[i + 1]);
        if (nextMatch != null) claveElector = nextMatch.group(0);
      }
    }

    // ── Fecha de nacimiento ───────────────────────────────────────────────────
    if (line.contains('NACIMIENTO') && i + 1 < lines.length) {
      fechaNac = dateRe.firstMatch(lines[i + 1])?.group(0) ?? lines[i + 1];
    }
    if (fechaNac == null && RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(line)) {
      fechaNac = line;
    }

    // ── Sexo ──────────────────────────────────────────────────────────────────
    if (line.startsWith('SEXO')) {
      final parts = line.split(RegExp(r'\s+'));
      sexo = parts.last;
    }
  }

  // ── CURP: take the 18 alphanumeric chars immediately before FECHA ───────────
  // Concatenate all stripped content between the CURP label and FECHA label,
  // then grab the LAST 18 chars (closest to FECHA) to avoid leading noise.
  if (fechaLabelIdx != -1) {
    final startIdx = curpLabelIdx != -1 ? curpLabelIdx + 1 : 0;
    final buffer = StringBuffer();
    for (int i = startIdx; i < fechaLabelIdx; i++) {
      buffer.write(lines[i].replaceAll(RegExp(r'[^A-Z0-9]'), ''));
    }
    final clean = buffer.toString();
    if (clean.length >= 18) {
      curp = clean.substring(clean.length - 18);
    } else if (clean.isNotEmpty) {
      curp = clean; // best effort
    }
  }

  return IneData(
    apellidoPaterno: ap?.isEmpty == true ? null : ap,
    apellidoMaterno: am?.isEmpty == true ? null : am,
    nombre: nombre?.isEmpty == true ? null : nombre,
    claveElector: claveElector,
    curp: curp,
    fechaNacimiento: fechaNac,
    sexo: sexo,
  );
}

String _cleanName(String s) =>
    s.replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÜÑ\s]'), '').trim();

// ─────────────────────────────────────────────────────────────────────────────
// INE back (reverso) data model
// ─────────────────────────────────────────────────────────────────────────────
class IneBackData {
  final String? idmex;

  const IneBackData({this.idmex});

  Map<String, String?> toMap() => {'idmex': idmex};

  String toJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}

// ─────────────────────────────────────────────────────────────────────────────
// Back parser
// ─────────────────────────────────────────────────────────────────────────────
IneBackData parseIneBackText(String rawText) {
  // Normalise: join all lines, uppercase
  final flat = rawText.toUpperCase();

  String? idmex;

  // Find "IDMEX" in the text
  final idmexStart = flat.indexOf('IDMEX');
  if (idmexStart != -1) {
    // Everything after "IDMEX"
    final after = flat.substring(idmexStart + 5);
    // Cut at "<<" if present
    final cutAt = after.indexOf('<<');
    final segment = cutAt != -1 ? after.substring(0, cutAt) : after;
    // Strip spaces and non-digit/letter noise, keep only digits
    // (sometimes OCR inserts spaces between digits)
    final digitsOnly = segment.replaceAll(RegExp(r'[^0-9]'), '');
    // Take the first 10 digits
    if (digitsOnly.length >= 10) {
      idmex = digitsOnly.substring(0, 10);
    } else if (digitsOnly.isNotEmpty) {
      idmex = digitsOnly; // best effort if less than 10
    }
  }

  return IneBackData(idmex: idmex);
}

// ─────────────────────────────────────────────────────────────────────────────
enum _IneSide { frente, reverso }

class OcrTestScreen extends StatefulWidget {
  const OcrTestScreen({super.key});

  @override
  State<OcrTestScreen> createState() => _OcrTestScreenState();
}

class _OcrTestScreenState extends State<OcrTestScreen> {
  File? _imageFile;
  String _rawText = '';
  IneData? _ineData;
  IneBackData? _ineBackData;
  _IneSide _selectedSide = _IneSide.frente;
  bool _isProcessing = false;
  bool _showRaw = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePictureAndRecognize() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo == null) return;

    setState(() {
      _imageFile = File(photo.path);
      _isProcessing = true;
      _rawText = '';
      _ineData = null;
      _ineBackData = null;
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognized = await textRecognizer.processImage(
        inputImage,
      );
      textRecognizer.close();

      final raw = recognized.text;

      // ignore: avoid_print
      print('─── OCR RAW ─────────────────────────────────');
      // ignore: avoid_print
      print(raw);

      if (_selectedSide == _IneSide.frente) {
        final ine = parseIneText(raw);
        // ignore: avoid_print
        print('─── INE FRENTE JSON ─────────────────────────');
        // ignore: avoid_print
        print(ine.toJson());
        // ignore: avoid_print
        print('─────────────────────────────────────────────');
        setState(() {
          _rawText = raw.isEmpty ? '(no se detectó texto)' : raw;
          _ineData = ine;
        });
      } else {
        final back = parseIneBackText(raw);
        // ignore: avoid_print
        print('─── INE REVERSO JSON ────────────────────────');
        // ignore: avoid_print
        print(back.toJson());
        // ignore: avoid_print
        print('─────────────────────────────────────────────');
        setState(() {
          _rawText = raw.isEmpty ? '(no se detectó texto)' : raw;
          _ineBackData = back;
        });
      }
    } catch (e) {
      setState(() => _rawText = 'Error: $e');
      debugPrint('OCR error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba OCR — INE'),
        backgroundColor: cs.surfaceContainerLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Side selector ───────────────────────────────────────────────
            SegmentedButton<_IneSide>(
              segments: const [
                ButtonSegment(
                  value: _IneSide.frente,
                  label: Text('Frente'),
                  icon: Icon(Icons.credit_card_outlined),
                ),
                ButtonSegment(
                  value: _IneSide.reverso,
                  label: Text('Reverso'),
                  icon: Icon(Icons.flip_to_back_outlined),
                ),
              ],
              selected: {_selectedSide},
              onSelectionChanged:
                  (s) => setState(() {
                    _selectedSide = s.first;
                    _imageFile = null;
                    _ineData = null;
                    _ineBackData = null;
                    _rawText = '';
                  }),
            ),
            const SizedBox(height: 16),

            // ── Image preview ───────────────────────────────────────────────
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedSide == _IneSide.frente
                                ? Icons.credit_card_outlined
                                : Icons.flip_to_back_outlined,
                            size: 52,
                            color: cs.onSurfaceVariant.withOpacity(0.4),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedSide == _IneSide.frente
                                ? 'Toma una foto del frente de tu INE'
                                : 'Toma una foto del reverso de tu INE',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 16),

            // ── Capture button ──────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _isProcessing ? null : _takePictureAndRecognize,
              icon:
                  _isProcessing
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.camera_alt_outlined),
              label: Text(
                _isProcessing ? 'Procesando…' : 'Tomar foto y procesar',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 24),

            // ── Frente results ──────────────────────────────────────────────
            if (_ineData != null) ...[
              _SectionHeader(
                icon: Icons.badge_outlined,
                label: 'Datos extraídos',
                color: cs.primary,
              ),
              const SizedBox(height: 10),
              _IneCard(ineData: _ineData!, colorScheme: cs),
              const SizedBox(height: 16),

              // ── JSON output ───────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.data_object_rounded,
                label: 'JSON',
                color: cs.tertiary,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.tertiaryContainer),
                ),
                child: SelectableText(
                  _ineData!.toJson(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Raw text toggle ────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _showRaw = !_showRaw),
                child: Row(
                  children: [
                    Icon(
                      _showRaw
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: cs.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showRaw ? 'Ocultar texto bruto' : 'Ver texto bruto',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showRaw) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _rawText,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ],

            // ── Reverso results ─────────────────────────────────────────────
            if (_ineBackData != null) ...[
              _SectionHeader(
                icon: Icons.qr_code_2_rounded,
                label: 'Datos extraídos — Reverso',
                color: cs.secondary,
              ),
              const SizedBox(height: 10),
              _IneBackCard(data: _ineBackData!, colorScheme: cs),
              const SizedBox(height: 16),
              _SectionHeader(
                icon: Icons.data_object_rounded,
                label: 'JSON',
                color: cs.tertiary,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.tertiaryContainer),
                ),
                child: SelectableText(
                  _ineBackData!.toJson(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showRaw = !_showRaw),
                child: Row(
                  children: [
                    Icon(
                      _showRaw
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: cs.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showRaw ? 'Ocultar texto bruto' : 'Ver texto bruto',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showRaw) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    _rawText,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _IneCard extends StatelessWidget {
  final IneData ineData;
  final ColorScheme colorScheme;

  const _IneCard({required this.ineData, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final fields = [
      ('Apellido paterno', ineData.apellidoPaterno),
      ('Apellido materno', ineData.apellidoMaterno),
      ('Nombre', ineData.nombre),
      ('Clave de elector', ineData.claveElector),
      ('CURP', ineData.curp),
      ('Fecha de nacimiento', ineData.fechaNacimiento),
      ('Sexo', ineData.sexo),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Column(
        children:
            fields.map((entry) {
              final (label, value) = entry;
              final found = value != null && value.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      found
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: found ? cs.primary : cs.outlineVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value ?? '—',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: found ? cs.onSurface : cs.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _IneBackCard extends StatelessWidget {
  final IneBackData data;
  final ColorScheme colorScheme;

  const _IneBackCard({required this.data, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final found = data.idmex != null && data.idmex!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.secondaryContainer),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            found
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: found ? cs.secondary : cs.outlineVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IDMEX (10 dígitos)',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  data.idmex ?? '—',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: found ? cs.onSurface : cs.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
