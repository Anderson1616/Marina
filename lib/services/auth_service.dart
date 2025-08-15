import '../models/usuario.dart';

class AuthService {
  static Usuario? _actual;
  static Usuario? get usuarioActual => _actual;

  static Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula red
    if (email.isEmpty || password.isEmpty) return false;
    _actual = Usuario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      nombre: email.split('@').first,
      rol: 'Tecnico',
    );
    return true;
  }

  static Future<void> logout() async {
    _actual = null;
  }
}
