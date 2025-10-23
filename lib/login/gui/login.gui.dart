import 'package:flutter/material.dart';
import 'package:gestione_negozio_abigliamento/login/jwt_api/error_list.dart';
import 'login.code.dart';
import '../jwt_api/url_validator.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jwtEndpointController = TextEditingController(text: 'simple-jwt-login/v1');

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _allowLocalhost = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _siteUrlController.text = loginCode.cachedSiteUrl ?? '';
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
                  Text(
                    'Accedi al tuo Negozio', 
                    style: theme.textTheme.headlineSmall, 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _siteUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL del Sito',
                      hintText: 'https://tuosito.com',
                      prefixIcon: Icon(Icons.public),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final correctedUrl = _autoCorrectUrl(value);
                      return UrlValidator.validateUrl(correctedUrl, allowLocalhost: _allowLocalhost);
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 8),

                  // Checkbox per connessioni locali
                  Row(
                    children: [
                      Checkbox(
                        value: _allowLocalhost,
                        onChanged: (value) => setState(() => _allowLocalhost = value ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _allowLocalhost = !_allowLocalhost),
                          child: Text(
                            'Consenti connessioni per sviluppo locale', 
                            style: theme.textTheme.bodySmall
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: _showLocalhostInfo,
                        tooltip: 'Informazioni sicurezza',
                      ),
                    ],
                  ),

                  // Banner di avviso per connessioni locali
                  if (_allowLocalhost)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modalità sviluppo: le connessioni HTTP non sono sicure.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username', 
                      prefixIcon: Icon(Icons.person)
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Inserisci username' : null,
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Inserisci password' : null,
                  ),
                  const SizedBox(height: 16),

                  // Impostazioni avanzate
                  ExpansionTile(
                    title: const Text(
                      'Impostazioni Avanzate', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                    leading: const Icon(Icons.settings, size: 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextFormField(
                          controller: _jwtEndpointController,
                          decoration: const InputDecoration(
                            labelText: 'Endpoint JWT Personalizzato (opzionale)', 
                            hintText: 'simple-jwt-login/v1', 
                            prefixIcon: Icon(Icons.api)
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Messaggio di successo
                  if (_successMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Messaggio di errore
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1), 
                        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              _errorMessage!, 
                              style: TextStyle(
                                color: theme.colorScheme.error, 
                                fontWeight: FontWeight.w500
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    onPressed: _isLoading ? null : _submitLogin,
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                        ) 
                      : const Text('ACCEDI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    // Corregge l'URL prima della validazione
    final correctedUrl = _autoCorrectUrl(_siteUrlController.text);
    _siteUrlController.text = correctedUrl ?? '';

    if (!_formKey.currentState!.validate()) return;
    
    setState(() { 
      _isLoading = true; 
      _errorMessage = null; 
      _successMessage = null;
    });

    try {
      await loginCode.performLogin(
        siteUrl: _siteUrlController.text,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        customJwtEndpoint: _jwtEndpointController.text.trim().isEmpty 
          ? null 
          : _jwtEndpointController.text.trim(),
      );

      // Login riuscito
      setState(() {
        _successMessage = 'Connessione riuscita! Sei stato autenticato correttamente.';
        _isLoading = false;
      });

      // Chiama il callback se fornito
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }

    } on AppException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      _passwordController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = "Si è verificato un errore sconosciuto.";
        _isLoading = false;
      });
       _passwordController.clear();
    }
  }

  void _showLocalhostInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security), 
            SizedBox(width: 8), 
            Text('Sviluppo Locale')
          ]
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Abilita questa opzione SOLO per connetterti a un sito WordPress in esecuzione sul tuo computer (localhost) o sulla tua rete locale (es. 192.168.x.x).\n\n⚠️ ATTENZIONE: Questo disabilita la protezione HTTPS, inviando le tue credenziali in chiaro. Non usarlo mai per siti in produzione.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: const Text('Ho Capito')
          )
        ],
      ),
    );
  }

  String? _autoCorrectUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    String corrected = url.trim();
    
    if (!corrected.startsWith('http')) {
      if (_allowLocalhost && UrlValidator.isLocalOrReservedIp(corrected.split(':')[0])) {
        corrected = 'http://$corrected';
      } else {
        corrected = 'https://$corrected';
      }
    }
    return corrected;
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