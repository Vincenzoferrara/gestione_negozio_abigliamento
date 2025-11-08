import 'package:flutter/material.dart';
import 'package:gestione_negozio_abigliamento/login/jwt_api/error_list.dart';
import 'package:gestione_negozio_abigliamento/login/jwt_api/jwt_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.code.dart';
import '../jwt_api/url_validator.dart';
import '../smartcard/smartcard_login_widget.dart';

/// Metodo di login disponibile
enum LoginMethod {
  credentials,  // Username/Password o API Key
  smartcard,    // Smartcard NFC/USB
}

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Chiavi per SharedPreferences
  static const String _prefKeyAuthType = 'login_auth_type';
  static const String _prefKeySiteUrl = 'login_site_url';

  final _formKey = GlobalKey<FormState>();
  final _siteUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jwtEndpointController = TextEditingController(text: 'simple-jwt-login/v1');
  final _consumerKeyController = TextEditingController();
  final _consumerSecretController = TextEditingController();

  AuthType _authType = AuthType.jwt;
  LoginMethod _loginMethod = LoginMethod.credentials;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _allowLocalhost = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Carica le preferenze salvate
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Carica il tipo di autenticazione (default: JWT)
      final authTypeStr = prefs.getString(_prefKeyAuthType);
      if (authTypeStr == 'api') {
        _authType = AuthType.woocommerceApi;
      } else {
        _authType = AuthType.jwt;
      }

      // Carica l'URL del sito (prima dalle preferenze, poi dalla cache)
      final savedUrl = prefs.getString(_prefKeySiteUrl);
      _siteUrlController.text = savedUrl ?? loginCode.cachedSiteUrl ?? '';
    });
  }

  /// Salva le preferenze correnti
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Salva il tipo di autenticazione
    await prefs.setString(
      _prefKeyAuthType,
      _authType == AuthType.jwt ? 'jwt' : 'api',
    );

    // Salva l'URL del sito
    await prefs.setString(_prefKeySiteUrl, _siteUrlController.text);
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

                  const SizedBox(height: 16),

                  // Pannello selezione METODO di login
                  _buildLoginMethodSelector(theme),

                  const SizedBox(height: 16),

                  // Pannello selezione tipo di autenticazione (solo se credenziali standard)
                  if (_loginMethod == LoginMethod.credentials)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo di Autenticazione',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          RadioListTile<AuthType>(
                            title: const Text('JWT Authentication'),
                            subtitle: const Text('Usa Simple JWT Login plugin'),
                            value: AuthType.jwt,
                            groupValue: _authType,
                            onChanged: (value) => setState(() => _authType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<AuthType>(
                            title: const Text('WooCommerce API'),
                            subtitle: const Text('Usa Consumer Key e Consumer Secret'),
                            value: AuthType.woocommerceApi,
                            groupValue: _authType,
                            onChanged: (value) => setState(() => _authType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
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

                  // Widget smartcard (se selezionato)
                  if (_loginMethod == LoginMethod.smartcard) ...[
                    SmartcardLoginWidget(
                      onLoginSuccess: () {
                        if (widget.onLoginSuccess != null) {
                          widget.onLoginSuccess!();
                        }
                      },
                    ),
                  ],

                  // Campi per JWT Authentication (solo se credenziali standard)
                  if (_loginMethod == LoginMethod.credentials && _authType == AuthType.jwt) ...[
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
                  ],

                  // Campi per WooCommerce API (solo se credenziali standard)
                  if (_loginMethod == LoginMethod.credentials && _authType == AuthType.woocommerceApi) ...[
                    TextFormField(
                      controller: _consumerKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Consumer Key',
                        prefixIcon: Icon(Icons.key),
                        hintText: 'ck_...'
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci Consumer Key' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _consumerSecretController,
                      decoration: InputDecoration(
                        labelText: 'Consumer Secret',
                        prefixIcon: const Icon(Icons.lock),
                        hintText: 'cs_...',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci Consumer Secret' : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Impostazioni avanzate (solo se credenziali standard)
                  if (_loginMethod == LoginMethod.credentials)
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
                        color: theme.colorScheme.error.withValues(alpha: 0.1), 
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
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
                  
                  // Bottone login (solo se credenziali standard)
                  if (_loginMethod == LoginMethod.credentials)
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
      if (_authType == AuthType.jwt) {
        // Login con JWT
        await loginCode.performLogin(
          siteUrl: _siteUrlController.text,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          customJwtEndpoint: _jwtEndpointController.text.trim().isEmpty
            ? null
            : _jwtEndpointController.text.trim(),
        );
      } else {
        // Login con WooCommerce API
        await loginCode.performApiLogin(
          siteUrl: _siteUrlController.text,
          consumerKey: _consumerKeyController.text.trim(),
          consumerSecret: _consumerSecretController.text.trim(),
        );
      }

      // Login riuscito - salva le preferenze
      await _savePreferences();

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
      if (_authType == AuthType.jwt) {
        _passwordController.clear();
      } else {
        _consumerSecretController.clear();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Si è verificato un errore sconosciuto.";
        _isLoading = false;
      });
      if (_authType == AuthType.jwt) {
        _passwordController.clear();
      } else {
        _consumerSecretController.clear();
      }
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

  /// Costruisce il selettore del metodo di login
  Widget _buildLoginMethodSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: theme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Metodo di Accesso',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Opzione credenziali standard
          InkWell(
            onTap: () => setState(() => _loginMethod = LoginMethod.credentials),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _loginMethod == LoginMethod.credentials
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: _loginMethod == LoginMethod.credentials
                      ? theme.primaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                  width: _loginMethod == LoginMethod.credentials ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.vpn_key,
                    color: _loginMethod == LoginMethod.credentials
                        ? theme.primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credenziali Standard',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _loginMethod == LoginMethod.credentials
                                ? theme.primaryColor
                                : null,
                          ),
                        ),
                        Text(
                          'Username/Password o API Keys',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loginMethod == LoginMethod.credentials)
                    Icon(Icons.check_circle, color: theme.primaryColor),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Opzione smartcard
          InkWell(
            onTap: () => setState(() => _loginMethod = LoginMethod.smartcard),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _loginMethod == LoginMethod.smartcard
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: _loginMethod == LoginMethod.smartcard
                      ? theme.primaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                  width: _loginMethod == LoginMethod.smartcard ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: _loginMethod == LoginMethod.smartcard
                        ? theme.primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smartcard',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _loginMethod == LoginMethod.smartcard
                                ? theme.primaryColor
                                : null,
                          ),
                        ),
                        Text(
                          'Login NFC o USB Reader',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loginMethod == LoginMethod.smartcard)
                    Icon(Icons.check_circle, color: theme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _siteUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _jwtEndpointController.dispose();
    _consumerKeyController.dispose();
    _consumerSecretController.dispose();
    super.dispose();
  }
}