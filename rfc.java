
//Jorge Muñoz Piñera No. Control: 21041270
import javax.swing.JOptionPane;

public class rfc {

    public static String removerConjunciones(String palabra) {
        String conj[] = new String[] { "da", "das", "de", "del", "der", "di", "die", "dd", "el", "la",
                "los", "las", "le", "les", "mac", "mc", "van", "von", "y" };

        for (int i = 0; i < conj.length; i++) {
            palabra = palabra.replaceAll(" " + conj[i] + " ", " ");
        }
        return palabra;
    }

    public static String leerNombres(String tipo) {
        String nom, ap, am, palabra = "";

        switch (tipo) {
            case "nom":
                nom = JOptionPane.showInputDialog(null, "Introduce tu nombre: ", "Nombres",
                        JOptionPane.QUESTION_MESSAGE).toLowerCase().trim();
                nom = " " + nom;
                nom = removerConjunciones(nom).trim();
                palabra = nom;
                break;
            case "ap":
                ap = JOptionPane.showInputDialog(null, "Introduce tu apellido paterno: ", "Apellidos",
                        JOptionPane.QUESTION_MESSAGE).toLowerCase().trim();
                ap = " " + ap;
                ap = removerConjunciones(ap).trim();
                palabra = ap;
                break;
            case "am":
                am = JOptionPane.showInputDialog(null, "Introduce tu apellido materno: ", "Apellidos",
                        JOptionPane.QUESTION_MESSAGE).toLowerCase().trim();
                am = " " + am;
                am = removerConjunciones(am).trim();
                palabra = am;
                break;
        }
        return palabra;
    }

    public static int leerNacimiento(String tipo) {
        int dn, mn, an, dato = 0;

        switch (tipo) {
            case "dn":
                dn = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce tu día de nacimiento (dd):",
                        "Día", JOptionPane.QUESTION_MESSAGE));
                while (dn > 31 || dn < 1) {
                    dn = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce un valor correcto:",
                            "Día", JOptionPane.ERROR_MESSAGE));
                }
                dato = dn;
                break;
            case "mn":
                mn = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce tu mes de nacimiento (mm):",
                        "Mes", JOptionPane.QUESTION_MESSAGE));
                while (mn > 12 || mn < 1) {
                    mn = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce un valor correcto:",
                            "Mes", JOptionPane.ERROR_MESSAGE));
                }
                dato = mn;
                break;
            case "an":
                an = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce tu año de nacimiento (aaaa):",
                        "Año", JOptionPane.QUESTION_MESSAGE));
                while (String.valueOf(an).length() != 4) {
                    an = Integer.valueOf(JOptionPane.showInputDialog(null, "Introduce un valor correcto:",
                            "Año", JOptionPane.ERROR_MESSAGE));
                }
                dato = an;
                break;
        }
        return dato;
    }

    public static String arreglarNombreyApellidos(String palabra, int numLetras, boolean ap) {
        boolean caes = false;
        String arreglado = "", caso = "";
        char abc[] = new char[] { 'a', 'á', 'ä', 'b', 'c', 'd', 'e', 'é', 'ë', 'f', 'g', 'h', 'i', 'í', 'ï', 'j', 'k',
                'l', 'm', 'n', 'o', 'ó', 'ö', 'p', 'q', 'r', 's', 't', 'u', 'ú', 'ü', 'v', 'w', 'x', 'y', 'z' };
        if (palabra.length() >= 5) {
            caso = palabra.substring(0, 5).trim();
        }
        switch (caso) {
            case "maria":
            case "maría":
                if (palabra.length() > 5) {
                    palabra = palabra.substring(6).trim();
                }
                break;
            case "jose":
            case "josé":
                if (palabra.length() > 4) {
                    palabra = palabra.substring(5).trim();
                }
                break;
        }

        if (ap == false) {
            for (int i = 0; i < abc.length; i++) {
                if (palabra.charAt(0) != abc[i]) {
                    arreglado = "x";
                } else {
                    arreglado = String.valueOf(palabra.charAt(0));
                    break;
                }
            }
            if (numLetras == 2) {
                if (palabra.length() < 2) {
                    arreglado += "x";
                } else {
                    for (int i = 0; i < abc.length; i++) {
                        if (palabra.charAt(1) != abc[i]) {
                            caes = true;
                        } else {
                            caes = false;
                            arreglado += String.valueOf(palabra.charAt(1));
                            break;
                        }
                    }
                }
                if (caes == true) {
                    arreglado += "x";
                }
            }
        } else if (ap == true) {
            for (int i = 0; i < abc.length; i++) {
                if (palabra.charAt(0) != abc[i]) {
                    arreglado = "x";
                } else {
                    arreglado = String.valueOf(palabra.charAt(0));
                    break;
                }
            }
            if (numLetras == 2) {
                for (int i = 1; i < palabra.length(); i++) {
                    if (palabra.charAt(i) == ('a') || palabra.charAt(i) == ('á') || palabra.charAt(i) == ('ä')) {
                        arreglado += "a";
                        break;
                    } else if (palabra.charAt(i) == ('e') || palabra.charAt(i) == ('é') || palabra.charAt(i) == ('ë')) {
                        arreglado += "e";
                        break;
                    } else if (palabra.charAt(i) == ('i') || palabra.charAt(i) == ('í') || palabra.charAt(i) == ('ï')) {
                        arreglado += "i";
                        break;
                    } else if (palabra.charAt(i) == ('o') || palabra.charAt(i) == ('ó') || palabra.charAt(i) == ('ö')) {
                        arreglado += "o";
                        break;
                    } else if (palabra.charAt(i) == ('u') || palabra.charAt(i) == ('ú') || palabra.charAt(i) == ('ü')) {
                        arreglado += "u";
                        break;
                    }
                }
                if (arreglado.length() == 1) {
                    arreglado += String.valueOf(palabra.charAt(1));
                }
            }
        }
        return arreglado;
    }

    public static String obtenerRFC(String nom, String ap, String am,
            int dn, int mn, int an) {
        String rfc = "";
        // Obtener apellido paterno:
        if (ap.length() > 2) {
            rfc += arreglarNombreyApellidos(ap, 2, true);
        } else {
            rfc += arreglarNombreyApellidos(ap, 1, true);
        }

        // Obtener apellido materno:
        if (am.length() != 0) {
            rfc += arreglarNombreyApellidos(am, 1, false);
        }

        // Obtener nombre:
        if (am.length() == 0 || ap.length() <= 2) {
            rfc += arreglarNombreyApellidos(nom, 2, false);
        } else {
            rfc += arreglarNombreyApellidos(nom, 1, false);
        }

        // Obtener año de nacimiento:
        if (String.valueOf(an).length() < 2) {
            rfc += "0" + an;
        } else if (String.valueOf(an).length() == 2) {
            rfc += an;
        } else {
            rfc += String.valueOf(an).substring(2, 4);
        }

        // Obtener mes de nacimiento:
        if (mn < 10) {
            rfc += "0" + mn;
        } else {
            rfc += String.valueOf(mn).substring(0, 2);
        }

        // Obtener día de nacimiento:
        if (dn < 10) {
            rfc += "0" + dn;
        } else {
            rfc += String.valueOf(dn).substring(0, 2);
        }

        return rfc+"-xxx";
    }

    public static String removerPalabraAntisonante(String palabra) {
        String antisonante[] = new String[] { "baca", "baka", "buei", "buey", "caca", "caco", "caga", "cago", "caka",
                "cako", "coge", "cogi", "coja", "coje", "coji", "cojo", "cola", "culo", "falo", "feto", "geta", "guei",
                "guey", "jeta", "joto", "kaca", "kaco", "kaga", "kago", "kaka", "kako", "koge", "kogi", "koja", "koje",
                "koji", "kojo", "kola", "kulo", "lilo", "loca", "loco", "loka", "loko", "mame", "mamo", "mear", "meas",
                "meon", "miar", "mion", "moco", "moko", "mula", "mulo", "naca", "naco", "peda", "pedo", "pene", "pipi",
                "pito", "popo", "puta", "puto", "qulo", "rata", "roba", "robe", "robo", "ruin", "seno", "teta", "vaca",
                "vaga", "vago", "vaka", "vuei", "vuey", "wuei", "wuey", "pdos" };
        for (int i = 0; i < antisonante.length; i++) {
            if (palabra.substring(0, 4).equals(antisonante[i])) {
                palabra = palabra.substring(0, 1) + "x" + palabra.substring(2, palabra.length());
            }
        }
        return palabra;
    }

    public static String removerAcentoyDiarisis(String palabra) {
        palabra = palabra.replaceAll("ä", "a");
        palabra = palabra.replaceAll("á", "a");

        palabra = palabra.replaceAll("ë", "e");
        palabra = palabra.replaceAll("é", "e");

        palabra = palabra.replaceAll("ï", "i");
        palabra = palabra.replaceAll("í", "i");

        palabra = palabra.replaceAll("ö", "o");
        palabra = palabra.replaceAll("ó", "o");

        palabra = palabra.replaceAll("ü", "u");
        palabra = palabra.replaceAll("ú", "u");
        return palabra;
    }

    public static void imprimir(String rfc) {
        rfc = rfc.toUpperCase();
        JOptionPane.showMessageDialog(null, "Tu RFC es: " + rfc, "RFC", JOptionPane.INFORMATION_MESSAGE);
    }

    public static void main(String[] args) {
        int dn = 0, mn = 0, an = 0;
        String nom = "", ap = "", am = "", rfc = "";

        // Leer datos
        nom = leerNombres("nom");
        ap = leerNombres("ap");
        am = leerNombres("am");
        dn = leerNacimiento("dn");
        mn = leerNacimiento("mn");
        an = leerNacimiento("an");

        // Obtener rfc
        rfc = obtenerRFC(nom, ap, am, dn, mn, an);

        // Remover palabra antisonante, dieresis y acento:
        rfc = removerPalabraAntisonante(rfc);
        rfc = removerAcentoyDiarisis(rfc);

        // Imprimir resultado:
        imprimir(rfc);
    }

}