import 'package:flutter/material.dart';

class ProdottiCreaCode {
  static Future<void> creaProdotto(
      BuildContext context,
      GlobalKey<FormState> formKey,
      TextEditingController nomeController,
      TextEditingController descrizioneController,
      TextEditingController prezzoController,
      Function setLoading,
      Function setError,
      ) async {
    if (formKey.currentState!.validate()) {
      setLoading(true);
      setError(null);

      // Qui dovrai inserire la logica per comunicare con il tuo sito WordPress
      // e creare il prodotto.
      // Per ora, simuliamo una risposta positiva dopo 2 secondi.

      await Future.delayed(Duration(seconds: 2));

      setLoading(false);
      // Simula un errore o un successo
      if (nomeController.text == 'errore') {
        setError('Errore durante la creazione del prodotto.');
      } else {
        //TODO: Mostra un messaggio di successo
        Navigator.pop(context); // Torna alla pagina precedente
      }
    }
  }
}