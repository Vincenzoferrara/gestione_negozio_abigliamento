import 'package:flutter/material.dart';

class LoginCode {
  // Funzione per il login
  Future<void> login(
      BuildContext context,
      GlobalKey<FormState> formKey,
      TextEditingController usernameController,
      TextEditingController passwordController,
      Function setLoading,
      Function setError,
      ) async {
    if (formKey.currentState!.validate()) {
      setLoading(true);
      setError(null);

      // Qui dovrai inserire la logica per comunicare con il tuo sito WordPress
      // e verificare le credenziali (username e password).
      // Per ora, simuliamo una risposta positiva dopo 2 secondi.

      await Future.delayed(Duration(seconds: 2));

      setLoading(false);
      // Simula un errore o un successo
      if (usernameController.text == 'test' && passwordController.text == 'password') {
        //TODO: Salva lo stato di login dell'app (es: SharedPreferences)
        Navigator.pushReplacementNamed(context, '/home'); // Naviga alla home
      } else {
        setError('Credenziali non valide.');
      }
    }
  }
}

// Istanza della classe LoginCode
final loginCode = LoginCode();