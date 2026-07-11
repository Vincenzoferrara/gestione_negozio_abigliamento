import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utenti.code.dart';
import 'class_user_global.dart';
import '../theme/theme.dart';

class UtentiStrings {
  static const String pageTitle = 'Gestione Utenti';
  static const String searchHint = 'Cerca per nome o email...';
  static const String noUsersFound = 'Nessun utente trovato';
  static const String selectUser = 'Seleziona un utente';
  static const String saveChanges = 'Salva Modifiche';
  static const String saving = 'Salvando...';
  static const String capabilities = 'Capabilities:';
  static const String metaData = 'Meta Dati:';
  static const String rolesPrefix = 'Ruoli: ';
  static const String addUserTooltip = 'Aggiungi Utente';
  static const String searchCapabilities = 'Cerca capabilities...';
  static const String confirmSuperAdmin =
      'Sei sicuro di voler rendere questo utente Super Admin?';
  static const String confirm = 'Conferma';
  static const String cancel = 'Annulla';
  static const String invalidUserData = 'Errore: Dati utente non validi';
}

/// Pagina principale per la gestione degli utenti
class UtentiPage extends StatefulWidget {
  const UtentiPage({super.key});

  @override
  UtentiGestisciPageState createState() => UtentiGestisciPageState();
}

class UtentiGestisciPageState extends State<UtentiPage> {
  final UtentiGestioneController _controller = UtentiGestioneController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _capabilitiesSearchController =
      TextEditingController();
  final TextEditingController _roleFilterController = TextEditingController();
  DateTime? _dateFilter;
  List<UserGlobal> utentiFiltrati = [];
  UserGlobal? utenteSelezionato;
  final Map<String, bool> _capabilitiesModificate =
      {}; // Traccia modifiche capabilities
  final Set<String> _ruoliSelezionati = <String>{};
  List<String> _ruoliEditabili = [];
  bool _isLoadingPermessi = false;
  bool _isLoadingCredenziali = false;
  List<Map<String, dynamic>> _appPasswords = [];
  List<Map<String, dynamic>> _wooApiKeys = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _caricaUtenti();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _capabilitiesSearchController.dispose();
    _roleFilterController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filtraUtenti();
    });
  }

  Future<void> _caricaUtenti() async {
    await _controller.caricaUtenti();
    if (mounted) {
      setState(() {
        utentiFiltrati = _controller.utenti
            .map((u) => UserGlobal.fromWordPressData(u))
            .toList();
      });
    }
  }

  void _filtraUtenti() {
    final query = _searchController.text.toLowerCase();
    final roleQuery = _roleFilterController.text.toLowerCase();
    setState(() {
      utentiFiltrati = _controller.utenti
          .where((utente) {
            if (utente is! Map<String, dynamic>) return false;

            // Filtro ricerca globale
            final matchesSearch =
                query.isEmpty ||
                (utente['name']?.toString().toLowerCase() ?? '').contains(
                  query,
                ) ||
                (utente['email']?.toString().toLowerCase() ?? '').contains(
                  query,
                ) ||
                (utente['username']?.toString().toLowerCase() ?? '').contains(
                  query,
                );

            // Filtro ruolo
            final userRoles = utente['roles'] as List<dynamic>?;
            final matchesRole =
                roleQuery.isEmpty ||
                (userRoles?.any(
                      (role) =>
                          role.toString().toLowerCase().contains(roleQuery),
                    ) ??
                    false);

            // Filtro data (se selezionata, utenti registrati dopo quella data)
            final matchesDate =
                _dateFilter == null ||
                (utente['registered_date'] != null &&
                    DateTime.tryParse(
                          utente['registered_date'],
                        )?.isAfter(_dateFilter!) ==
                        true);

            // Escludi clienti
            final roles = utente['roles'] as List<dynamic>?;
            final notCustomer = roles == null || !roles.contains('customer');

            return matchesSearch && matchesRole && matchesDate && notCustomer;
          })
          .map((u) => UserGlobal.fromWordPressData(u))
          .toList();
    });
  }

  void _selezionaUtente(UserGlobal utente) {
    setState(() {
      utenteSelezionato = utente;
      _capabilitiesModificate.clear(); // Reset modifiche
      _ruoliSelezionati
        ..clear()
        ..addAll(utente.roles ?? const <String>[]);
      _ruoliEditabili = [];
      _appPasswords = [];
      _wooApiKeys = [];
    });
    final userId = utente.id;
    if (userId != null && userId > 0) {
      _caricaDettaglioPermessi(userId);
      _caricaCredenziali(userId);
    }
  }

  Future<void> _caricaDettaglioPermessi(int userId) async {
    setState(() {
      _isLoadingPermessi = true;
    });
    try {
      final data = await _controller.caricaPermessiUtente(userId);
      final roles = (data['roles'] is List)
          ? List<String>.from(data['roles'] as List)
          : <String>[];
      final editable = (data['editable_roles'] is List)
          ? List<String>.from(data['editable_roles'] as List)
          : <String>[];

      if (!mounted) {
        return;
      }
      setState(() {
        _ruoliSelezionati
          ..clear()
          ..addAll(roles);
        _ruoliEditabili = editable;
      });
    } catch (_) {
      // Non blocca la pagina utenti se endpoint non disponibile.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPermessi = false;
        });
      }
    }
  }

  Future<void> _caricaCredenziali(int userId) async {
    setState(() {
      _isLoadingCredenziali = true;
    });
    try {
      final appPasswords = await _controller.listaAppPassword(userId);
      final wooKeys = await _controller.listaWooApiKeys(userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _appPasswords = appPasswords;
        _wooApiKeys = wooKeys;
      });
    } catch (_) {
      // Endpoint potrebbe non essere disponibile su installazioni vecchie.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredenziali = false;
        });
      }
    }
  }

  void _salvaModifiche(UserGlobal utente) {
    final userId = utente.id;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID utente non valido')));
      return;
    }

    final rawUser = _controller.utenti.firstWhere(
      (u) =>
          u is Map<String, dynamic> &&
          (u['id']?.toString() ?? '') == userId.toString(),
      orElse: () => <String, dynamic>{'id': userId},
    );

    _controller
        .salvaCapabilities(rawUser, _capabilitiesModificate)
        .then((ok) {
          if (!mounted) {
            return;
          }
          if (ok) {
            setState(() {
              _capabilitiesModificate.clear();
            });
            _aggiornaUtenteSelezionatoDalController(userId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permessi aggiornati')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _controller.errorMessage ?? 'Errore nel salvataggio permessi',
                ),
              ),
            );
          }
        })
        .catchError((e) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Errore: $e')));
        });
  }

  Future<void> _salvaRuoli(UserGlobal utente) async {
    final userId = utente.id;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID utente non valido')));
      return;
    }

    final roles = _ruoliSelezionati.toList()..sort();
    final ok = await _controller.salvaRuoliUtente(userId: userId, roles: roles);
    if (!mounted) {
      return;
    }
    if (ok) {
      _aggiornaUtenteSelezionatoDalController(userId);
      _caricaDettaglioPermessi(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ruoli aggiornati')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Errore nel salvataggio ruoli',
          ),
        ),
      );
    }
  }

  void _aggiornaUtenteSelezionatoDalController(int userId) {
    final idx = _controller.utenti.indexWhere(
      (u) =>
          u is Map<String, dynamic> &&
          (u['id']?.toString() ?? '') == userId.toString(),
    );
    if (idx < 0) {
      return;
    }
    final raw = _controller.utenti[idx];
    if (raw is! Map<String, dynamic>) {
      return;
    }
    final updated = UserGlobal.fromWordPressData(raw);
    setState(() {
      utenteSelezionato = updated;
      final filteredIdx = utentiFiltrati.indexWhere((u) => u.id == userId);
      if (filteredIdx >= 0) {
        utentiFiltrati[filteredIdx] = updated;
      }
    });
  }

  Future<void> _revocaAppPassword(UserGlobal utente, String uuid) async {
    final userId = utente.id;
    if (userId == null || userId <= 0 || uuid.isEmpty) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoca App Password'),
        content: const Text('Confermi la revoca di questa credenziale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoca'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    try {
      await _controller.revocaAppPassword(userId: userId, uuid: uuid);
      if (!mounted) {
        return;
      }
      await _caricaCredenziali(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('App password revocata')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore revoca app password: $e')));
    }
  }

  Future<void> _revocaWooApiKey(UserGlobal utente, int keyId) async {
    final userId = utente.id;
    if (userId == null || userId <= 0 || keyId <= 0) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoca Woo API Key'),
        content: const Text('Confermi la revoca di questa chiave API?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoca'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    try {
      await _controller.revocaWooApiKey(userId: userId, keyId: keyId);
      if (!mounted) {
        return;
      }
      await _caricaCredenziali(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Woo API key revocata')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore revoca Woo API key: $e')));
    }
  }

  Future<void> _generaAppPassword(UserGlobal utente) async {
    final userId = utente.id;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID utente non valido')));
      return;
    }

    final nameController = TextEditingController(text: 'Gestione Negozio App');
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova App Password'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome credenziale'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Genera'),
          ),
        ],
      ),
    );
    if (approved != true) {
      return;
    }

    try {
      final resp = await _controller.generaAppPassword(
        userId: userId,
        name: nameController.text.trim(),
      );
      if (!mounted) {
        return;
      }

      final appPassword = (resp['app_password'] ?? '').toString();
      if (appPassword.isEmpty) {
        throw Exception('Nessuna password ricevuta dal server');
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App Password generata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copia ora la password, verra mostrata solo questa volta.',
              ),
              const SizedBox(height: 12),
              SelectableText(appPassword),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: appPassword));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App password copiata')),
                  );
                }
              },
              child: const Text('Copia'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
      await _caricaCredenziali(userId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore generazione password: $e')),
      );
    }
  }

  Future<void> _generaWooApiKey(UserGlobal utente) async {
    final userId = utente.id;
    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID utente non valido')));
      return;
    }

    final descriptionController = TextEditingController(
      text: 'Gestione Negozio App',
    );
    var permissions = 'read_write';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Nuova Woo API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: permissions,
                decoration: const InputDecoration(labelText: 'Permessi'),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read')),
                  DropdownMenuItem(value: 'write', child: Text('Write')),
                  DropdownMenuItem(
                    value: 'read_write',
                    child: Text('Read & Write'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setLocalState(() {
                    permissions = v;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Genera'),
            ),
          ],
        ),
      ),
    );
    if (approved != true) {
      return;
    }

    try {
      final resp = await _controller.generaWooApiKey(
        userId: userId,
        description: descriptionController.text.trim(),
        permissions: permissions,
      );
      if (!mounted) {
        return;
      }

      final consumerKey = (resp['consumer_key'] ?? '').toString();
      final consumerSecret = (resp['consumer_secret'] ?? '').toString();
      if (consumerKey.isEmpty || consumerSecret.isEmpty) {
        throw Exception('Chiavi non ricevute dal server');
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Woo API Key generata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copia ora le chiavi, il secret verra mostrato solo questa volta.',
              ),
              const SizedBox(height: 10),
              const Text('Consumer Key:'),
              SelectableText(consumerKey),
              const SizedBox(height: 8),
              const Text('Consumer Secret:'),
              SelectableText(consumerSecret),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final text =
                    'consumer_key=$consumerKey\nconsumer_secret=$consumerSecret';
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chiavi Woo copiate')),
                  );
                }
              },
              child: const Text('Copia'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
      await _caricaCredenziali(userId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore generazione chiavi Woo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(UtentiStrings.pageTitle), elevation: 2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 800;
          final bool isTablet = constraints.maxWidth > 600;
          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildListaUtenti()),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  flex: 1,
                  child: utenteSelezionato != null
                      ? _buildDettagliUtente(utenteSelezionato!)
                      : _buildEmptyState(),
                ),
              ],
            );
          } else if (isTablet) {
            return Column(
              children: [
                Expanded(child: _buildListaUtenti()),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: utenteSelezionato != null
                      ? _buildDettagliUtente(utenteSelezionato!)
                      : _buildEmptyState(),
                ),
              ],
            );
          } else {
            return Column(children: [_buildListaUtenti()]);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: UtentiStrings.addUserTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListaUtenti() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: UtentiStrings.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
          ),
        ),
        Expanded(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : utentiFiltrati.isEmpty
              ? const Center(child: Text(UtentiStrings.noUsersFound))
              : RepaintBoundary(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: utentiFiltrati.length,
                    itemBuilder: (context, index) {
                      final utente = utentiFiltrati[index];
                      final isSelected = utente == utenteSelezionato;
                      return _UtenteCard(
                        utente: utente,
                        isSelected: isSelected,
                        onTap: () => _selezionaUtente(utente),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDettagliUtente(UserGlobal utente) {
    final name = utente.displayName;
    final email = utente.email ?? 'N/D';
    final roles = utente.rolesString;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).extension<AppColorExtension>()!.gradientStart,
                Theme.of(context).extension<AppColorExtension>()!.gradientEnd,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header con avatar e info base
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${UtentiStrings.rolesPrefix}$roles',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Pulsante salva
                ElevatedButton.icon(
                  onPressed: _controller.isSaving
                      ? null
                      : () => _salvaModifiche(utente),
                  icon: _controller.isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _controller.isSaving
                        ? UtentiStrings.saving
                        : UtentiStrings.saveChanges,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _generaAppPassword(utente),
                      icon: const Icon(Icons.password),
                      label: const Text('Genera App Password'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _generaWooApiKey(utente),
                      icon: const Icon(Icons.vpn_key),
                      label: const Text('Genera Woo API Key'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Sezioni espandibili
                Expanded(
                  child: ListView(
                    children: [
                      _buildExpandableSection(
                        title: 'Informazioni Base',
                        icon: Icons.info,
                        children: [
                          _buildInfoRowWithIcon(
                            Icons.person,
                            'ID',
                            utente.id?.toString() ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.account_circle,
                            'Username',
                            utente.username ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.badge,
                            'First Name',
                            utente.firstName ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.badge,
                            'Last Name',
                            utente.lastName ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.face,
                            'Nickname',
                            utente.nickname ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.link,
                            'URL',
                            utente.url ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.description,
                            'Description',
                            utente.description ?? 'N/D',
                          ),
                          _buildInfoRowWithIcon(
                            Icons.calendar_today,
                            'Registered Date',
                            utente.registeredDate?.toString() ?? 'N/D',
                          ),
                        ],
                      ),
                      _buildRuoliSection(utente),
                      _buildCredenzialiSection(utente),
                      _buildCapabilitiesSectionEditable(
                        utente,
                        true,
                      ), // Assume admin
                      _buildMetaSection(utente),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        children: children,
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuoliSection(UserGlobal utente) {
    if (_isLoadingPermessi) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final rolesUi = _ruoliEditabili.isNotEmpty
        ? _ruoliEditabili
        : List<String>.from(utente.roles ?? const <String>[]);

    return _buildExpandableSection(
      title: 'Ruoli',
      icon: Icons.shield,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rolesUi
                  .map(
                    (role) => FilterChip(
                      label: Text(role),
                      selected: _ruoliSelezionati.contains(role),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _ruoliSelezionati.add(role);
                          } else if (_ruoliSelezionati.length > 1) {
                            _ruoliSelezionati.remove(role);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: _controller.isSaving
                    ? null
                    : () => _salvaRuoli(utente),
                icon: const Icon(Icons.save),
                label: const Text('Salva ruoli'),
              ),
              const SizedBox(width: 10),
              Text(
                'Selezionati: ${_ruoliSelezionati.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCredenzialiSection(UserGlobal utente) {
    final appRows = _appPasswords;
    final wooRows = _wooApiKeys;

    return _buildExpandableSection(
      title: 'Credenziali API',
      icon: Icons.key,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final userId = utente.id;
                  if (userId != null && userId > 0) {
                    _caricaCredenziali(userId);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Aggiorna'),
              ),
              if (_isLoadingCredenziali) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Application Passwords',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (appRows.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Nessuna app password attiva'),
            ),
          )
        else
          ...appRows.map((row) {
            final name = (row['name'] ?? 'Senza nome').toString();
            final uuid = (row['uuid'] ?? '').toString();
            final lastUsed = (row['last_used'] ?? '').toString();
            final subtitle = lastUsed.isEmpty
                ? 'Mai usata'
                : 'Ultimo uso: $lastUsed';
            return ListTile(
              dense: true,
              title: Text(name),
              subtitle: Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Revoca',
                onPressed: uuid.isNotEmpty
                    ? () => _revocaAppPassword(utente, uuid)
                    : null,
              ),
            );
          }),
        const Divider(height: 18),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Woo API Keys',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (wooRows.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Nessuna Woo API key attiva'),
            ),
          )
        else
          ...wooRows.map((row) {
            final keyId = int.tryParse((row['key_id'] ?? '').toString()) ?? 0;
            final description = (row['description'] ?? 'Senza descrizione')
                .toString();
            final permissions = (row['permissions'] ?? '').toString();
            final trunc = (row['truncated_key'] ?? '').toString();
            final subtitle = '${permissions.toUpperCase()} - ...$trunc';
            return ListTile(
              dense: true,
              title: Text(description),
              subtitle: Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Revoca',
                onPressed: keyId > 0
                    ? () => _revocaWooApiKey(utente, keyId)
                    : null,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCapabilitiesSectionEditable(UserGlobal utente, bool isAdmin) {
    final capabilitiesRaw = utente.capabilities;
    if (capabilitiesRaw == null || capabilitiesRaw.isEmpty) {
      return const SizedBox.shrink();
    }
    final capabilities = capabilitiesRaw;

    // Filtro per ricerca
    final searchQuery = _capabilitiesSearchController.text.toLowerCase();
    final filteredCapabilities = capabilities.entries
        .where((entry) => entry.key.toLowerCase().contains(searchQuery))
        .map((e) => e.key)
        .toList();

    // Raggruppa capabilities filtrate per sezione
    final inventario = <String>[];
    final woocommerce = <String>[];
    final wordpress = <String>[];

    for (final cap in filteredCapabilities) {
      final key = cap.toLowerCase();
      if (key.contains('mgws') || key.contains('inventory') || key.contains('stock')) {
        inventario.add(cap);
      } else if (key.contains('prodotto') ||
          key.contains('woocommerce') ||
          key.contains('shop')) {
        woocommerce.add(cap);
      } else {
        wordpress.add(cap);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UtentiStrings.capabilities,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _capabilitiesSearchController,
            decoration: InputDecoration(
              hintText: UtentiStrings.searchCapabilities,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) => setState(() {}), // Ricarica la UI
          ),
        ),
        if (inventario.isNotEmpty)
          _buildCapabilitySection(
            'Inventario',
            inventario,
            capabilities,
            isAdmin,
          ),
        if (woocommerce.isNotEmpty)
          _buildCapabilitySection(
            'WooCommerce',
            woocommerce,
            capabilities,
            isAdmin,
          ),
        if (wordpress.isNotEmpty)
          _buildCapabilitySection(
            'WordPress',
            wordpress,
            capabilities,
            isAdmin,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCapabilitySection(
    String title,
    List<String> entries,
    Map<String, dynamic> capabilities,
    bool isAdmin,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                children: [
                  Expanded(child: Text(entry)),
                  if (isAdmin)
                    Switch(
                      value:
                          _capabilitiesModificate[entry] ??
                          (capabilities[entry] == true),
                      onChanged:
                          UtentiGestioneController.capabilityWhitelist.contains(
                            entry,
                          )
                          ? (value) async {
                              // Controllo conferma per super admin
                              if (entry.toLowerCase().contains('super') &&
                                  value) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(UtentiStrings.confirm),
                                    content: Text(
                                      UtentiStrings.confirmSuperAdmin,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(UtentiStrings.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(UtentiStrings.confirm),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }

                              setState(() {
                                _capabilitiesModificate[entry] = value;
                              });
                            }
                          : null,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetaSection(UserGlobal utente) {
    final metaRaw = utente.meta;
    if (metaRaw == null || metaRaw.isEmpty) {
      return const SizedBox.shrink();
    }
    final meta = metaRaw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UtentiStrings.metaData,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        ...meta.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Text('${entry.key}: ${entry.value}'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(UtentiStrings.selectUser),
        ],
      ),
    );
  }
}

class _UtenteCard extends StatelessWidget {
  final UserGlobal utente;
  final bool isSelected;
  final VoidCallback onTap;

  const _UtenteCard({
    required this.utente,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  utente.displayName
                      .split(' ')
                      .map((e) => e[0])
                      .join('')
                      .toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      utente.displayName,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    Text(
                      utente.email ?? 'N/D',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'ID: ${utente.id ?? 'N/D'}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
