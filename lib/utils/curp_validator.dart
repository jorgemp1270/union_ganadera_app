/// CURP Validator - Translated from Java RFC validator
/// Original author: Jorge Muñoz Piñera No. Control: 21041270

class CurpValidator {
  static const List<String> _conjunciones = [
    "da",
    "das",
    "de",
    "del",
    "der",
    "di",
    "die",
    "dd",
    "el",
    "la",
    "los",
    "las",
    "le",
    "les",
    "mac",
    "mc",
    "van",
    "von",
    "y",
  ];

  static const List<String> _palabrasAntisonantes = [
    "baca",
    "baka",
    "buei",
    "buey",
    "caca",
    "caco",
    "caga",
    "cago",
    "caka",
    "cako",
    "coge",
    "cogi",
    "coja",
    "coje",
    "coji",
    "cojo",
    "cola",
    "culo",
    "falo",
    "feto",
    "geta",
    "guei",
    "guey",
    "jeta",
    "joto",
    "kaca",
    "kaco",
    "kaga",
    "kago",
    "kaka",
    "kako",
    "koge",
    "kogi",
    "koja",
    "koje",
    "koji",
    "kojo",
    "kola",
    "kulo",
    "lilo",
    "loca",
    "loco",
    "loka",
    "loko",
    "mame",
    "mamo",
    "mear",
    "meas",
    "meon",
    "miar",
    "mion",
    "moco",
    "moko",
    "mula",
    "mulo",
    "naca",
    "naco",
    "peda",
    "pedo",
    "pene",
    "pipi",
    "pito",
    "popo",
    "puta",
    "puto",
    "qulo",
    "rata",
    "roba",
    "robe",
    "robo",
    "ruin",
    "seno",
    "teta",
    "vaca",
    "vaga",
    "vago",
    "vaka",
    "vuei",
    "vuey",
    "wuei",
    "wuey",
    "pdos",
  ];

  static const List<String> _abecedario = [
    'a',
    'á',
    'ä',
    'b',
    'c',
    'd',
    'e',
    'é',
    'ë',
    'f',
    'g',
    'h',
    'i',
    'í',
    'ï',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'ó',
    'ö',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'ú',
    'ü',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  /// Remove conjunctions from a word
  static String removerConjunciones(String palabra) {
    String resultado = palabra;
    for (String conj in _conjunciones) {
      resultado = resultado.replaceAll(' $conj ', ' ');
    }
    return resultado;
  }

  /// Fix name and surnames for RFC/CURP generation
  static String arreglarNombreyApellidos(
    String palabra,
    int numLetras,
    bool esApellido,
  ) {
    String arreglado = "";

    // Handle special cases for first names
    if (palabra.length >= 5) {
      String caso = palabra.substring(0, 5).trim();
      if (caso == "maria" || caso == "maría") {
        if (palabra.length > 5) {
          palabra = palabra.substring(6).trim();
        }
      } else if (caso.substring(0, 4) == "jose" ||
          caso.substring(0, 4) == "josé") {
        if (palabra.length > 4) {
          palabra = palabra.substring(5).trim();
        }
      }
    }

    if (!esApellido) {
      // For names
      if (_abecedario.contains(palabra[0])) {
        arreglado = palabra[0];
      } else {
        arreglado = "x";
      }

      if (numLetras == 2) {
        if (palabra.length < 2) {
          arreglado += "x";
        } else {
          if (_abecedario.contains(palabra[1])) {
            arreglado += palabra[1];
          } else {
            arreglado += "x";
          }
        }
      }
    } else {
      // For surnames (need first vowel)
      if (_abecedario.contains(palabra[0])) {
        arreglado = palabra[0];
      } else {
        arreglado = "x";
      }

      if (numLetras == 2) {
        bool found = false;
        for (int i = 1; i < palabra.length; i++) {
          String char = palabra[i];
          if (char == 'a' || char == 'á' || char == 'ä') {
            arreglado += 'a';
            found = true;
            break;
          } else if (char == 'e' || char == 'é' || char == 'ë') {
            arreglado += 'e';
            found = true;
            break;
          } else if (char == 'i' || char == 'í' || char == 'ï') {
            arreglado += 'i';
            found = true;
            break;
          } else if (char == 'o' || char == 'ó' || char == 'ö') {
            arreglado += 'o';
            found = true;
            break;
          } else if (char == 'u' || char == 'ú' || char == 'ü') {
            arreglado += 'u';
            found = true;
            break;
          }
        }
        if (!found && arreglado.length == 1) {
          arreglado += palabra.length > 1 ? palabra[1] : 'x';
        }
      }
    }

    return arreglado;
  }

  /// Generate RFC/CURP (first 10 characters) from personal data
  static String generarCURP({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required int dia,
    required int mes,
    required int anio,
  }) {
    // Clean and prepare data
    String nom = ' ${nombre.toLowerCase().trim()}';
    String ap = ' ${apellidoPaterno.toLowerCase().trim()}';
    String am = ' ${apellidoMaterno.toLowerCase().trim()}';

    nom = removerConjunciones(nom).trim();
    ap = removerConjunciones(ap).trim();
    am = removerConjunciones(am).trim();

    String curp = "";

    // Get paternal surname (2 letters)
    if (ap.length > 2) {
      curp += arreglarNombreyApellidos(ap, 2, true);
    } else {
      curp += arreglarNombreyApellidos(ap, 1, true);
    }

    // Get maternal surname (1 letter)
    if (am.isNotEmpty) {
      curp += arreglarNombreyApellidos(am, 1, false);
    }

    // Get name (1 or 2 letters depending on previous conditions)
    if (am.isEmpty || ap.length <= 2) {
      curp += arreglarNombreyApellidos(nom, 2, false);
    } else {
      curp += arreglarNombreyApellidos(nom, 1, false);
    }

    // Get year (2 digits)
    String anioStr = anio.toString();
    if (anioStr.length < 2) {
      curp += "0$anio";
    } else if (anioStr.length == 2) {
      curp += anioStr;
    } else {
      curp += anioStr.substring(2, 4);
    }

    // Get month (2 digits)
    if (mes < 10) {
      curp += "0$mes";
    } else {
      curp += mes.toString().substring(0, 2);
    }

    // Get day (2 digits)
    if (dia < 10) {
      curp += "0$dia";
    } else {
      curp += dia.toString().substring(0, 2);
    }

    // Remove antisonant words
    curp = removerPalabraAntisonante(curp);

    // Remove accents and diaeresis
    curp = removerAcentoyDiarisis(curp);

    return curp.toUpperCase() + "-XXX";
  }

  /// Validate if a CURP matches the given personal data
  static bool validarCURP({
    required String curp,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required int dia,
    required int mes,
    required int anio,
  }) {
    String curpGenerado = generarCURP(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      dia: dia,
      mes: mes,
      anio: anio,
    );

    // Compare first 10 characters (without homoclave)
    String curpLimpio = curp.replaceAll('-', '').toUpperCase();
    String generadoLimpio = curpGenerado.replaceAll('-', '').toUpperCase();

    if (curpLimpio.length < 10 || generadoLimpio.length < 10) {
      return false;
    }

    return curpLimpio.substring(0, 10) == generadoLimpio.substring(0, 10);
  }

  /// Remove antisonant words (offensive words) from CURP
  static String removerPalabraAntisonante(String palabra) {
    if (palabra.length < 4) return palabra;

    String primerosCuatro = palabra.substring(0, 4);
    for (String antisonante in _palabrasAntisonantes) {
      if (primerosCuatro == antisonante) {
        return palabra.substring(0, 1) + "x" + palabra.substring(2);
      }
    }
    return palabra;
  }

  /// Remove accents and diaeresis
  static String removerAcentoyDiarisis(String palabra) {
    return palabra
        .replaceAll('ä', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ë', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ï', 'i')
        .replaceAll('í', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ú', 'u');
  }

  /// Validate CURP format (basic validation)
  static bool validarFormatoCURP(String curp) {
    // Remove hyphens for validation
    String curpLimpio = curp.replaceAll('-', '').toUpperCase();

    // CURP should be 18 characters
    if (curpLimpio.length != 18) {
      return false;
    }

    // Basic regex pattern for CURP
    // 4 letters, 6 digits (YYMMDD), 1 letter (sex), 2 letters (state), 3 consonants, 2 alphanumeric
    RegExp curpPattern = RegExp(
      r'^[A-Z]{4}\d{6}[HMX][A-Z]{2}[A-Z]{3}[A-Z0-9]{2}$',
    );

    return curpPattern.hasMatch(curpLimpio);
  }
}
