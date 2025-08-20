import 'package:flutter/material.dart';
import 'login.code.dart';
import '../jwt_api/url_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jwtEndpointController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _allowLocalhost = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (loginCode.cachedSiteUrl != null) {
      _siteUrlController.text = loginCode.cachedSiteUrl!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Accedi al tuo Negozio', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _siteUrlController,
                    decoration: InputDecoration(labelText: 'URL del tuo sito WordPress', hintText: 'nomesito.com', prefixIcon: const Icon(Icons.language)),
                    keyboardType: TextInputType.url,
                    validator: (value) => UrlValidator.validateUrl(_autoCorrectUrl(value), allowLocalhost: _allowLocalhost),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 8),

                  CheckboxListTile(
                    title: Text('Consenti connessioni per sviluppo locale', style: theme.textTheme.bodySmall),
                    value: _allowLocalhost,
                    onChanged: (value) {
                      setState(() { _allowLocalhost = value ?? false; });
                      _formKey.currentState?.validate();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  
                  if (_allowLocalhost)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Modalità sviluppo: le connessioni HTTP non sono sicure.', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                    validator: (value) => (value == null || value.isEmpty) ? 'Inserisci il tuo username' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) => (value == null || value.isEmpty) ? 'Inserisci la tua password' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  ExpansionTile(
                    title: const Text('Impostazioni Avanzate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    leading: const Icon(Icons.settings, size: 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextFormField(
                          controller: _jwtEndpointController,
                          decoration: const InputDecoration(labelText: 'Endpoint JWT Personalizzato (opzionale)', hintText: 'es. simple-jwt-login/v1/auth', prefixIcon: Icon(Icons.api)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                 if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Usiamo SelectableText invece di Text
                      child: SelectableText(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center, // Opzionale: per centrare il testo
                      ),
                    ),


                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isLoading ? null : _submitLogin,
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('ACCEDI E TESTA'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 String? _autoCorrectUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    String corrected = url.trim().toLowerCase(); // Lavoriamo sempre in minuscolo per coerenza

    // Se l'utente scrive solo "localhost" o "localhost:porta", lo aiutiamo
    if (corrected.startsWith('localhost')) {
        if (!corrected.startsWith('http')) {
            return 'http://$corrected'; // Per localhost usiamo http
        }
        return corrected;
    }
    
    // Per tutto il resto, aggiungiamo https se manca
    if (!corrected.startsWith('http')) {
      return 'https://$corrected';
    }
    
    return corrected;
  }

  Future<void> _submitLogin() async {
    final correctedUrl = _autoCorrectUrl(_siteUrlController.text);
    _siteUrlController.text = correctedUrl ?? '';

    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await loginCode.performLoginAndTestCreation(
        context: context,
        siteUrl: _siteUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        customJwtEndpoint: _jwtEndpointController.text.trim().isEmpty ? null : _jwtEndpointController.text.trim(),
        
        // --- MODIFICA CHIAVE QUI ---
        // Passiamo una funzione che verrà eseguita solo in caso di successo.
        onSuccess: () {
          setState(() {
            _isLoading = false;
            _passwordController.clear(); // Pulisce la password dopo il successo
          });

          // Mostra la SnackBar di successo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Connessione riuscita e prodotto di test creato!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        // --- FINE MODIFICA ---
      );

   } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _passwordController.clear();
    }
  }

  void _showLocalhostInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(children: [Icon(Icons.security), SizedBox(width: 8), Text('Sviluppo Locale')]),
        content: const SingleChildScrollView(
          child: Text('Abilita questa opzione SOLO per connetterti a un sito WordPress in esecuzione sul tuo computer (localhost) o sulla tua rete locale (es. 192.168.x.x).\n\n⚠️ ATTENZIONE: Questo disabilita la protezione HTTPS, inviando le tue credenziali in chiaro. Non usarlo mai per siti in produzione.'),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ho Capito'))],
      ),
    );
  }

  @override
  void dispose() {
    _siteUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _jwtEndpointController.dispose();
    super.dispose();
  }
}