import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Parsed data containers
// ─────────────────────────────────────────────────────────────────────────────

class IneFrontData {
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? nombre;
  final String? claveElector;
  final String? curp;
  final String? fechaNacimiento; // dd/MM/yyyy
  final String? sexo; // 'H' or 'M'

  const IneFrontData({
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.nombre,
    this.claveElector,
    this.curp,
    this.fechaNacimiento,
    this.sexo,
  });
}

class IneBackData {
  final String? idmex; // 10-digit code

  const IneBackData({this.idmex});
}

// ─────────────────────────────────────────────────────────────────────────────
// Main utility class
// ─────────────────────────────────────────────────────────────────────────────

class OcrUtil {
  OcrUtil._();

  // ── Public helpers ──────────────────────────────────────────────────────────

  static Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      recognizer.close();
    }
  }

  static Future<IneFrontData> scanIneFront(File imageFile) async {
    final raw = await extractText(imageFile);
    return parseIneFront(raw);
  }

  static Future<IneBackData> scanIneBack(File imageFile) async {
    final raw = await extractText(imageFile);
    return parseIneBack(raw);
  }

  // ── Front parser ────────────────────────────────────────────────────────────

  static IneFrontData parseIneFront(String rawText) {
    final lines =
        rawText
            .split('\n')
            .map((l) => l.trim().toUpperCase())
            .where((l) => l.isNotEmpty)
            .toList();

    String? ap, am, nombre, claveElector, curp, fechaNac, sexo;

    final claveRe = RegExp(r'[A-ZÑ0-9]{18}');
    final dateRe = RegExp(r'\d{2}/\d{2}/\d{4}');

    final curpLabelIdx = lines.indexWhere(
      (l) => l == 'CURP' || l.startsWith('CURP '),
    );
    final fechaLabelIdx = lines.indexWhere((l) => l.contains('NACIMIENTO'));

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Nombre block: NOMBRE → AP → AM → nombre
      if (line == 'NOMBRE' && i + 3 < lines.length) {
        ap = _cleanName(lines[i + 1]);
        am = _cleanName(lines[i + 2]);
        nombre = _cleanName(lines[i + 3]);
      }

      // Clave de elector
      if (line.contains('CLAVE') && line.contains('ELECTOR')) {
        final match = claveRe.firstMatch(line);
        if (match != null) {
          claveElector = match.group(0);
        } else if (i + 1 < lines.length) {
          final next = claveRe.firstMatch(lines[i + 1]);
          if (next != null) claveElector = next.group(0);
        }
      }

      // Fecha de nacimiento
      if (line.contains('NACIMIENTO') && i + 1 < lines.length) {
        fechaNac = dateRe.firstMatch(lines[i + 1])?.group(0) ?? lines[i + 1];
      }
      if (fechaNac == null && RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(line)) {
        fechaNac = line;
      }

      // Sexo
      if (line.startsWith('SEXO')) {
        final parts = line.split(RegExp(r'\s+'));
        final candidate = parts.last;
        if (candidate == 'H' || candidate == 'M') sexo = candidate;
      }
    }

    // CURP: concatenate stripped chars between CURP label and FECHA label,
    // then take the LAST 18 chars (closest to FECHA, avoids leading noise)
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
        curp = clean;
      }
    }

    return IneFrontData(
      apellidoPaterno: _nullIfEmpty(ap),
      apellidoMaterno: _nullIfEmpty(am),
      nombre: _nullIfEmpty(nombre),
      claveElector: _nullIfEmpty(claveElector),
      curp: _nullIfEmpty(curp),
      fechaNacimiento: _nullIfEmpty(fechaNac),
      sexo: _nullIfEmpty(sexo),
    );
  }

  // ── Back parser ─────────────────────────────────────────────────────────────

  static IneBackData parseIneBack(String rawText) {
    final flat = rawText.toUpperCase();
    String? idmex;

    final idmexStart = flat.indexOf('IDMEX');
    if (idmexStart != -1) {
      final after = flat.substring(idmexStart + 5);
      final cutAt = after.indexOf('<<');
      final segment = cutAt != -1 ? after.substring(0, cutAt) : after;
      final digitsOnly = segment.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length >= 10) {
        idmex = digitsOnly.substring(0, 10);
      } else if (digitsOnly.isNotEmpty) {
        idmex = digitsOnly;
      }
    }

    return IneBackData(idmex: idmex);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static String _cleanName(String s) =>
      s.replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÜÑ\s]'), '').trim();

  static String? _nullIfEmpty(String? s) => (s == null || s.isEmpty) ? null : s;
}
