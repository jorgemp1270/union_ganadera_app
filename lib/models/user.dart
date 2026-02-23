class User {
  final String id;
  final String curp;
  final String rol;
  final DateTime createdAt;

  User({
    required this.id,
    required this.curp,
    required this.rol,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      curp: json['curp'],
      rol: json['rol'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curp': curp,
      'rol': rol,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserRegistration {
  final String curp;
  final String contrasena;
  final String nombre;
  final String apellidoP;
  final String apellidoM;
  final String sexo;
  final DateTime fechaNac;
  final String claveElector;
  final String idmex;

  UserRegistration({
    required this.curp,
    required this.contrasena,
    required this.nombre,
    required this.apellidoP,
    required this.apellidoM,
    required this.sexo,
    required this.fechaNac,
    required this.claveElector,
    required this.idmex,
  });

  Map<String, dynamic> toJson() {
    return {
      'curp': curp,
      'contrasena': contrasena,
      'nombre': nombre,
      'apellido_p': apellidoP,
      'apellido_m': apellidoM,
      'sexo': sexo,
      'fecha_nac': fechaNac.toIso8601String().split('T')[0],
      'clave_elector': claveElector,
      'idmex': idmex,
    };
  }
}

class VeterinarianRegistration {
  final String curp;
  final String contrasena;
  final String nombre;
  final String apellidoP;
  final String apellidoM;
  final String sexo;
  final DateTime fechaNac;
  final String claveElector;
  final String idmex;
  final String cedula;

  VeterinarianRegistration({
    required this.curp,
    required this.contrasena,
    required this.nombre,
    required this.apellidoP,
    required this.apellidoM,
    required this.sexo,
    required this.fechaNac,
    required this.claveElector,
    required this.idmex,
    required this.cedula,
  });

  Map<String, dynamic> toFormData() {
    return {
      'curp': curp,
      'contrasena': contrasena,
      'nombre': nombre,
      'apellido_p': apellidoP,
      'apellido_m': apellidoM,
      'sexo': sexo,
      'fecha_nac': fechaNac.toIso8601String().split('T')[0],
      'clave_elector': claveElector,
      'idmex': idmex,
      'cedula': cedula,
    };
  }
}
