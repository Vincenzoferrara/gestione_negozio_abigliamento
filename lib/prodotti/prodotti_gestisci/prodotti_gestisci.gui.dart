import 'package:flutter/material.dart';
import 'prodotti_gestisci.code.dart';
import '../class_prodotti.dart';
import '../../theme/theme.dart'; // Assicurati che il percorso sia corretto

// Funzione helper per convertire stringhe HEX in Color
Color hexToColor(String code) {
  // Rimuove '#' e aggiunge il prefisso per l'opacità completa se non presente
  final hexString = code.startsWith('#') ? code.substring(1) : code;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // Ritorna un colore di default in caso di errore di parsing
    return Colors.grey;
  }
}


// Definisce un widget StatefulWidget, che può avere uno stato che cambia nel tempo.
class ProdottiGestisciPage extends StatefulWidget {
  // Costruttore del widget. Aggiunto {super.key} per conformità con le buone pratiche.
  const ProdottiGestisciPage({super.key});

  // L'annotazione @override indica che stiamo sovrascrivendo un metodo della classe base.
  @override
  // Il metodo createState è obbligatorio per uno StatefulWidget e crea la sua classe di stato.
  ProdottiGestisciPageState createState() => ProdottiGestisciPageState();
}

class ProdottiGestisciPageState extends State<ProdottiGestisciPage> {
  // Crea e inizializza un'istanza finale (non modificabile) del controller della logica.
  final ProdottiGestioneController _controller = ProdottiGestioneController();

  // Metodo del ciclo di vita chiamato una sola volta quando il widget viene creato e inserito nell'albero.
  @override
  void initState() {
    // È buona norma chiamare sempre il metodo initState della classe genitore.
    super.initState();
    // Chiama la nostra funzione per avviare il caricamento dei prodotti.
    _caricaProdotti();
  }

  // Definisce una funzione asincrona per caricare i prodotti.
  Future<void> _caricaProdotti() async {
    // La parola chiave 'await' attende che il caricamento dei prodotti sia completato.
    await _controller.caricaProdotti();
    // Chiama setState per notificare a Flutter che lo stato è cambiato e la UI deve essere ricostruita.
    setState(() {});
  }

  // Il metodo build è responsabile della costruzione dell'interfaccia utente del widget.
  @override
  Widget build(BuildContext context) {
    // Scaffold implementa la struttura di base di una schermata Material Design.
    return Scaffold(
      // Imposta il colore di sfondo della pagina prendendolo dal tema globale.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Il corpo principale dello Scaffold.
      body: LayoutBuilder(
        // LayoutBuilder fornisce i vincoli del genitore (es. la larghezza) per creare UI responsive.
        builder: (context, constraints) {
          // Determina se lo schermo è "piccolo" basandosi su una larghezza massima di 800 pixel.
          bool isSmallScreen = constraints.maxWidth < 800;
          // Se lo schermo è piccolo, costruisce e restituisce il layout per mobile.
          if (isSmallScreen) {
            // Ritorna il widget del layout mobile.
            return _buildMobileLayout();
            // Altrimenti, se lo schermo è grande.
          } else {
            // Ritorna il widget del layout desktop.
            return _buildDesktopLayout();
          }
        },
      ),
      // Il FloatingActionButton (pulsante fluttuante) della pagina.
      floatingActionButton: LayoutBuilder(
        // Usa un LayoutBuilder per decidere se mostrare il FAB in base alla larghezza.
        builder: (context, constraints) {
          // Calcola di nuovo se lo schermo è piccolo.
          bool isSmallScreen = constraints.maxWidth < 800;
          // Se lo schermo è piccolo (layout mobile), mostra il FAB.
          if (isSmallScreen) {
            // Ritorna il widget del FAB.
            return _buildFAB();
            // Altrimenti (su schermi grandi).
          } else {
            // Ritorna un widget vuoto e invisibile (il FAB verrà messo nel pannello dei dettagli).
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Metodo che costruisce l'interfaccia per schermi piccoli (mobile).
  Widget _buildMobileLayout() {
    // Column dispone i suoi figli in una colonna verticale.
    return Column(
      // La lista dei widget figli della colonna.
      children: [
        // Expanded fa sì che il figlio occupi lo spazio disponibile in base al fattore 'flex'.
        Expanded(
          // Assegna un fattore di flessibilità 2.
          flex: 2,
          // Il figlio è il widget della lista dei prodotti.
          child: _ProductListWidget(
            // Passa il controller al widget figlio.
            controller: _controller,
            // Passa la funzione di callback per aggiornare lo stato.
            onStateChanged: _updateState,
          ),
        ),
        // Condizione: se un prodotto è selezionato...
        if (_controller.hasProdottoSelezionato) ...[
          // ...mostra una linea di separazione.
          Divider(height: 1, color: Theme.of(context).dividerColor),
          // E mostra i dettagli del prodotto.
          Expanded(
            // Assegna un fattore di flessibilità 1 (occupa meno spazio della lista).
            flex: 1,
            // Il figlio è il widget dei dettagli del prodotto.
            child: _ProductDetailsWidget(
              // Passa il controller.
              controller: _controller,
              // Passa la callback.
              onStateChanged: _updateState,
            ),
          ),
        ],
      ],
    );
  }

  // Metodo che costruisce l'interfaccia per schermi grandi (desktop).
  Widget _buildDesktopLayout() {
    // Row dispone i suoi figli in una riga orizzontale.
    return Row(
      // La lista dei widget figli della riga.
      children: [
        // Expanded per il pannello della lista a sinistra.
        Expanded(
          // Fattore di flessibilità 3 (occupa più spazio del pannello dei dettagli).
          flex: 3,
          // Il figlio è il widget della lista dei prodotti.
          child: _ProductListWidget(
            // Passa il controller.
            controller: _controller,
            // Passa la callback.
            onStateChanged: _updateState,
          ),
        ),
        // VerticalDivider disegna una linea verticale tra i due pannelli.
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        // Expanded per il pannello dei dettagli a destra.
        Expanded(
          // Fattore di flessibilità 2.
          flex: 2,
          // Stack permette di sovrapporre i widget uno sopra l'altro.
          child: Stack(
            // I figli dello Stack.
            children: [
              // L'espressione ternaria decide quale widget mostrare come base dello Stack.
              _controller.hasProdottoSelezionato
                  // Se un prodotto è selezionato, mostra il widget dei dettagli.
                  ? _ProductDetailsWidget(
                      controller: _controller,
                      onStateChanged: _updateState,
                    )
                  // Altrimenti, mostra il messaggio di stato vuoto.
                  : _buildEmptyState(),
              // Positioned posiziona il suo figlio in un punto specifico dello Stack.
              Positioned(
                // Lo ancora a 20 pixel dal basso.
                bottom: 20,
                // Lo ancora a 20 pixel da destra.
                right: 20,
                // Il figlio è il pulsante di creazione.
                child: _buildCreateButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Metodo che costruisce la schermata da visualizzare quando nessun prodotto è selezionato.
  Widget _buildEmptyState() {
    // Ottiene l'oggetto del tema corrente.
    final theme = Theme.of(context);
    // Center centra il suo figlio sia orizzontalmente che verticalmente.
    return Center(
      // Column per disporre icona e testo verticalmente.
      child: Column(
        // Allinea i figli al centro dell'asse verticale.
        mainAxisAlignment: MainAxisAlignment.center,
        // La lista dei figli.
        children: [
          // Widget Icon per visualizzare un'icona.
          Icon(
            // L'icona specifica da mostrare.
            Icons.inventory_2_outlined,
            // La dimensione dell'icona.
            size: 64,
            color: theme.iconTheme.color?.withAlpha((255 * 0.4).round()),
          ),
          // SizedBox crea uno spazio vuoto, in questo caso verticale.
          const SizedBox(height: 16),
          // Widget Text per visualizzare una stringa.
          Text(
            // Il contenuto testuale.
            'Seleziona un prodotto',
            // Lo stile del testo, copiato dal tema e modificato.
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withAlpha(
                (255 * 0.7).round(),
              ),
            ),
          ),
          // Un altro widget Text.
          Text(
            // Il contenuto testuale.
            'per vedere i dettagli',
            // Stile personalizzato.
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withAlpha(
                (255 * 0.5).round(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metodo che costruisce il FloatingActionButton principale (solo per mobile).
  Widget _buildFAB() {
    // Ottiene l'oggetto dell'estensione personalizzata del tema.
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    // Ritorna il widget FloatingActionButton.
    return FloatingActionButton(
      // La funzione da eseguire quando il pulsante viene premuto.
      onPressed: () => Navigator.pushNamed(context, '/prodotti/crea'),
      // Testo di aiuto mostrato alla pressione prolungata (accessibilità).
      tooltip: 'Crea Nuovo Prodotto',
      // Imposta lo sfondo del FAB a trasparente, perché il container figlio ha già il suo sfondo.
      backgroundColor: Colors.transparent,
      // Elevazione del FAB impostata a 0 per rimuovere la sua ombra predefinita.
      elevation: 0,
      child: Container(
        // Decorazione del container per creare l'effetto gradiente e ombra.
        decoration: BoxDecoration(
          // Gradiente lineare come sfondo.
          gradient: LinearGradient(
            // I colori del gradiente, presi dal tema personalizzato.
            colors: [
              customColors.fabGradientStart,
              customColors.fabGradientEnd,
            ],
            // Punto di inizio del gradiente.
            begin: Alignment.topLeft,
            // Punto di fine del gradiente.
            end: Alignment.bottomRight,
          ),
          // Raggio degli angoli per renderlo circolare.
          borderRadius: BorderRadius.circular(28),
          // Lista delle ombre da applicare.
          boxShadow: [
            // Definizione di un'ombra.
            BoxShadow(
              // Colore dell'ombra.
              color: Theme.of(
                context,
              ).primaryColor.withAlpha((255 * 0.4).round()),
              // Sfocatura dell'ombra.
              blurRadius: 12,
              // Spostamento dell'ombra (x, y).
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Il figlio del container decorato è l'icona.
        child: Icon(
          // L'icona da usare (un "+").
          Icons.add,
          // La dimensione dell'icona.
          size: 28,
          // Il colore dell'icona (adatto per uno sfondo primario).
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  // Metodo che costruisce il pulsante di creazione per il layout desktop.
  Widget _buildCreateButton() {
    // Ottiene i colori personalizzati dal tema.
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    // Ritorna un FloatingActionButton, che ha già la forma e l'ombra corrette.
    return FloatingActionButton(
      // Azione da eseguire alla pressione.
      onPressed: () => Navigator.pushNamed(context, '/prodotti/crea'),
      // Testo di aiuto per l'accessibilità.
      tooltip: 'Crea Nuovo Prodotto',
      // Il figlio del pulsante.
      child: Container(
        // Decorazione per lo sfondo a gradiente.
        decoration: BoxDecoration(
          // Gradiente di sfondo.
          gradient: LinearGradient(
            // Colori del gradiente.
            colors: [
              customColors.fabGradientStart,
              customColors.fabGradientEnd,
            ],
            // Inizio del gradiente.
            begin: Alignment.topLeft,
            // Fine del gradiente.
            end: Alignment.bottomRight,
          ),
          // Forma del contenitore (circolare).
          shape: BoxShape.circle,
        ),
        // Center per centrare l'icona all'interno del contenitore.
        child: Center(
          // Icona del "+".
          child: Icon(
            // Icona specifica.
            Icons.add,
            // Dimensione dell'icona.
            size: 28,
            // Colore dell'icona.
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // Metodo per aggiornare lo stato.
  void _updateState() {
    // Chiama setState per dire a Flutter di ricostruire la UI.
    setState(() {});
  }
}

// Definisce un widget stateless per la lista dei prodotti.
class _ProductListWidget extends StatelessWidget {
  // Proprietà finale per il controller.
  final ProdottiGestioneController controller;
  // Proprietà finale per la callback di aggiornamento.
  final VoidCallback onStateChanged;

  // Costruttore del widget.
  const _ProductListWidget({
    required this.controller,
    required this.onStateChanged,
  });

  // Metodo che costruisce l'interfaccia del widget.
  @override
  Widget build(BuildContext context) {
    // Column per disporre filtri e lista verticalmente.
    return Column(
      // Figli della colonna.
      children: [
        // Il widget per i filtri di ricerca e ordinamento.
        _FiltriWidget(controller: controller, onStateChanged: onStateChanged),
        // Expanded fa sì che la lista occupi tutto lo spazio verticale rimanente.
        Expanded(child: _buildList(context)),
      ],
    );
  }

  // Metodo che costruisce la ListView.
  Widget _buildList(BuildContext context) {
    // Container che funge da sfondo per la lista.
    return Container(
      // Colore di sfondo preso dal tema.
      color: Theme.of(context).scaffoldBackgroundColor,
      // ListView.builder è il modo più performante per costruire liste.
      child: ListView.builder(
        // Padding attorno all'intera lista.
        padding: const EdgeInsets.all(8),
        // Il numero di elementi nella lista.
        itemCount: controller.prodotti.length,
        // La funzione che costruisce ogni singolo elemento della lista.
        itemBuilder: (context, index) => _ProductListItem(
          // Passa il prodotto corrispondente all'indice corrente.
          prodotto: controller.prodotti[index],
          // Controlla se questo prodotto è quello attualmente selezionato.
          isSelected: controller.isProdottoSelezionato(
            controller.prodotti[index],
          ),
          // Azione da eseguire quando l'elemento viene toccato.
          onTap: () {
            // Chiama il metodo del controller per selezionare il prodotto.
            controller.selezionaProdotto(controller.prodotti[index]);
            // Chiama la callback per aggiornare la UI della pagina principale.
            onStateChanged();
          },
        ),
      ),
    );
  }
}

// Widget StatefulWidget per i filtri, così può gestire lo stato del campo di testo.
class _FiltriWidget extends StatefulWidget {
  // Il controller della logica.
  final ProdottiGestioneController controller;
  // La callback per aggiornare la UI.
  final VoidCallback onStateChanged;

  // Costruttore del widget.
  const _FiltriWidget({
    required this.controller,
    required this.onStateChanged,
  });

  // Metodo che crea l'oggetto di stato.
  @override
  _FiltriWidgetState createState() => _FiltriWidgetState();
}

// La classe di Stato per _FiltriWidget.
class _FiltriWidgetState extends State<_FiltriWidget> {
  // Un controller per gestire il testo del campo di ricerca.
  final _searchController = TextEditingController();

  // Metodo chiamato all'inizializzazione del widget.
  @override
  void initState() {
    // Chiama il metodo della classe base.
    super.initState();
    // Imposta il testo del controller con il valore del filtro attuale (utile se si ricarica la pagina).
    _searchController.text = widget.controller.filtroRicerca;
  }

  // Metodo chiamato quando il widget viene eliminato definitivamente.
  @override
  void dispose() {
    // Rilascia le risorse del controller di testo per prevenire memory leak.
    _searchController.dispose();
    // Chiama il metodo della classe base.
    super.dispose();
  }

  // Funzione di utilità per convertire un valore enum di ordinamento in una stringa leggibile.
  String _getOrdinamentoText(OrdinamentoProdotti ordinamento) {
    // Switch per controllare il valore dell'enum.
    switch (ordinamento) {
      // Caso per nome crescente.
      case OrdinamentoProdotti.nomeCrescente:
        return 'Nome (A-Z)';
      // Caso per nome decrescente.
      case OrdinamentoProdotti.nomeDecrescente:
        return 'Nome (Z-A)';
      // Caso per prezzo crescente.
      case OrdinamentoProdotti.prezzoCrescente:
        return 'Prezzo (Crescente)';
      // Caso per prezzo decrescente.
      case OrdinamentoProdotti.prezzoDecrescente:
        return 'Prezzo (Decrescente)';
      // Caso per nessun ordinamento.
      case OrdinamentoProdotti.nessuno:
        // Ritorna il testo segnaposto.
        return 'Ordina per...';
    }
  }

  // Metodo che costruisce l'interfaccia del widget dei filtri.
  @override
  Widget build(BuildContext context) {
    // Padding per distanziare i filtri dai bordi.
    return Padding(
      // Valore del padding su tutti i lati.
      padding: const EdgeInsets.all(12.0),
      // Column per disporre i filtri verticalmente.
      child: Column(
        // Figli della colonna.
        children: [
          // TextField è il widget per l'input di testo.
          TextField(
            // Associa il controller di testo al widget.
            controller: _searchController,
            // InputDecoration definisce l'aspetto del campo di testo.
            decoration: InputDecoration(
              // Testo segnaposto mostrato quando il campo è vuoto.
              hintText: 'Cerca per nome, SKU, categoria...',
              // Icona mostrata all'inizio (a sinistra) del campo.
              prefixIcon: const Icon(Icons.search),
              // Icona mostrata alla fine (a destra) del campo.
              suffixIcon: widget.controller.hasFiltroAttivo
                  // Se c'è un filtro attivo, mostra un IconButton per cancellare.
                  ? IconButton(
                      // Icona del pulsante.
                      icon: const Icon(Icons.clear),
                      // Azione da eseguire quando premuto.
                      onPressed: () {
                        // Svuota il testo nel controller.
                        _searchController.clear();
                        // Chiama il metodo del controller logico per cancellare il filtro.
                        widget.controller.cancellaFiltro();
                        // Aggiorna la UI.
                        widget.onStateChanged();
                      },
                    )
                  // Altrimenti, non mostra nessuna icona.
                  : null,
            ),
            // Funzione chiamata ogni volta che il valore del testo cambia.
            onChanged: (value) {
              // Aggiorna il filtro nel controller logico.
              widget.controller.setFiltroRicerca(value);
              // Aggiorna la UI.
              widget.onStateChanged();
            },
          ),
          // Spazio verticale tra i due filtri.
          const SizedBox(height: 10),
          // Contenitore per personalizzare l'aspetto del DropdownButton.
          Container(
            // Padding interno orizzontale.
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            // Decorazione del contenitore.
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              // Angoli arrotondati.
              borderRadius: BorderRadius.circular(12.0),
               border: Border.all(
                color: Theme.of(context).inputDecorationTheme.enabledBorder!.borderSide.color,
              ),
            ),
            // DropdownButton è il widget per il menu a tendina.
            child: DropdownButton<OrdinamentoProdotti>(
              // Il valore attualmente selezionato nel dropdown.
              value: widget.controller.ordinamentoCorrente,
              // Fa sì che il dropdown si espanda per tutta la larghezza del contenitore.
              isExpanded: true,
              // Rimuove la linea di sottolineatura predefinita.
              underline: const SizedBox(),
              // L'icona del dropdown.
              icon: Icon(Icons.sort, color: Theme.of(context).primaryColor),
              // Funzione chiamata quando viene selezionato un nuovo elemento.
              onChanged: (OrdinamentoProdotti? nuovoValore) {
                // Controlla se il nuovo valore non è nullo.
                if (nuovoValore != null) {
                  // Imposta il nuovo criterio di ordinamento nel controller logico.
                  widget.controller.setOrdinamento(nuovoValore);
                  // Aggiorna la UI.
                  widget.onStateChanged();
                }
              },
              // La lista di elementi del menu.
              items: OrdinamentoProdotti.values.map((ordinamento) {
                // Per ogni valore dell'enum, crea un DropdownMenuItem.
                return DropdownMenuItem<OrdinamentoProdotti>(
                  // Il valore associato a questo elemento.
                  value: ordinamento,
                  // Il widget da visualizzare per questo elemento (un testo).
                  child: Text(_getOrdinamentoText(ordinamento)),
                );
              }).toList(), // Converte l'iterable risultante in una lista.
            ),
          ),
        ],
      ),
    );
  }
}

// Widget che rappresenta un singolo elemento (prodotto) nella lista.
class _ProductListItem extends StatelessWidget {
  // Il dato del prodotto da visualizzare.
  final ProdottoWoo prodotto;
  // Flag che indica se l'elemento è attualmente selezionato.
  final bool isSelected;
  // Funzione da eseguire al tocco.
  final VoidCallback onTap;

  // Costruttore del widget.
  const _ProductListItem({
    required this.prodotto,
    required this.isSelected,
    required this.onTap,
  });

  // Metodo che costruisce l'interfaccia del widget.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Ottiene i colori personalizzati dall'estensione del tema.
    final customColors = theme.extension<AppColorExtension>()!;
    // Crea un oggetto con le informazioni del prodotto già formattate per la visualizzazione.
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    // Card è un pannello Material Design con angoli arrotondati e ombra.
    return Card(
      // Margine attorno alla card.
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      // Elevazione (ombra) che cambia se la card è selezionata.
      elevation: isSelected ? 8 : 2,
      // Colore dell'ombra, visibile solo se selezionata.
      shadowColor: isSelected
          ? Theme.of(context).primaryColor.withAlpha((255 * 0.3).round())
          : null,
      // Forma della card.
      shape: RoundedRectangleBorder(
        // Raggio degli angoli.
        borderRadius: BorderRadius.circular(12),
        // Bordo che appare solo se la card è selezionata.
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      // Colore di sfondo della card, diverso se selezionata.
      color: isSelected ? customColors.selectedCardBackground : theme.cardColor,
      // InkWell aggiunge l'effetto "ripple" (onda) al tocco.
      child: InkWell(
        // La funzione da chiamare al tocco.
        onTap: onTap,
        // Raggio degli angoli per l'effetto ripple.
        borderRadius: BorderRadius.circular(12),
        // Padding interno alla card.
        child: Padding(
          // Valore del padding.
          padding: const EdgeInsets.all(12),
          // LayoutBuilder per scegliere il layout in base alla larghezza.
          child: LayoutBuilder(
            // Funzione builder.
            builder: (context, constraints) {
              // Se la larghezza è maggiore di 600 pixel...
              return constraints.maxWidth > 600
                  // ...usa il layout largo.
                  ? _buildWideLayout(context, displayInfo)
                  // ...altrimenti usa il layout compatto.
                  : _buildCompactLayout(context, displayInfo);
            },
          ),
        ),
      ),
    );
  }

  // Metodo per costruire il layout largo (desktop).
  Widget _buildWideLayout(BuildContext context, ProdottoDisplayInfo info) {
    // Row per disporre gli elementi orizzontalmente.
    return Row(
      // Figli della riga.
      children: [
        // Sezione del nome.
        Expanded(flex: 3, child: _buildNameSection(context, info)),
        // Sezione del prezzo.
        Expanded(flex: 2, child: _buildPriceWidget(context)),
        // Sezione della categoria.
        Expanded(flex: 2, child: _buildCategorySection(context, info)),
        // "Chip" con il numero di varianti.
        _buildVariantsChip(context),
      ],
    );
  }

  // Metodo per costruire il layout compatto (mobile).
  Widget _buildCompactLayout(BuildContext context, ProdottoDisplayInfo info) {
    // Ottiene i colori personalizzati.
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    // Colonna per disporre gli elementi verticalmente.
    return Column(
      // Allinea i figli a sinistra.
      crossAxisAlignment: CrossAxisAlignment.start,
      // Figli della colonna.
      children: [
        // Riga per nome e prezzo.
        Row(
          // Figli della riga.
          children: [
            // Sezione del nome.
            Expanded(child: _buildNameSection(context, info)),
            // Widget del prezzo.
            _buildPriceWidget(context),
          ],
        ),
        // Spazio verticale.
        const SizedBox(height: 4),
        // Riga per ID, categoria e altre info.
        Row(
          // Figli della riga.
          children: [
            // Testo dell'ID.
            Text(
              // Contenuto testuale.
              'ID: ${info.id}',
              // Stile del testo.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withAlpha((255 * 0.7).round()),
              ),
            ),
            // Spazio orizzontale.
            const SizedBox(width: 16),
            // Testo della categoria.
            Text(info.categoria, style: Theme.of(context).textTheme.bodySmall),
            // Spacer occupa tutto lo spazio disponibile, spingendo gli elementi successivi a destra.
            const Spacer(),
            // Icona per lo stato di disponibilità.
            Icon(
              // Sceglie l'icona in base allo stato `inStock`.
              prodotto.inStock ? Icons.check_circle : Icons.cancel,
              // Dimensione dell'icona.
              size: 14,
              // Colore dell'icona, che cambia in base allo stato.
              color: prodotto.inStock
                  ? customColors.stockAvailable
                  : customColors.stockUnavailable,
            ),
            // Spazio orizzontale.
            const SizedBox(width: 4),
            // Testo che indica il numero di varianti.
            Text(
              // Ottiene la stringa breve per il conteggio delle varianti.
              ProdottoUtils.getVariantiCountShort(prodotto.varianti.length),
              // Stile del testo.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withAlpha((255 * 0.7).round()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Metodo che costruisce la sezione con nome e SKU.
  Widget _buildNameSection(BuildContext context, ProdottoDisplayInfo info) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Colonna per i due testi.
    return Column(
      // Allinea i testi a sinistra.
      crossAxisAlignment: CrossAxisAlignment.start,
      // Figli della colonna.
      children: [
        // Testo del nome del prodotto.
        Text(
          // Contenuto testuale.
          info.nome,
          // Stile del testo.
          style: theme.textTheme.titleMedium?.copyWith(
            // Grassetto.
            fontWeight: FontWeight.bold,
            // Colore che cambia se l'elemento è selezionato.
            color: isSelected
                ? Theme.of(context).primaryColor
                : theme.textTheme.titleMedium?.color,
          ),
        ),
        // Testo con ID e SKU.
        Text(
          // Contenuto testuale.
          'ID: ${info.id} • SKU: ${info.sku}',
          // Stile del testo.
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha(
              (255 * 0.7).round(),
            ),
          ),
        ),
      ],
    );
  }

  // Metodo che costruisce la sezione con categoria e disponibilità.
  Widget _buildCategorySection(BuildContext context, ProdottoDisplayInfo info) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Ottiene i colori personalizzati.
    final customColors = theme.extension<AppColorExtension>()!;
    // Colonna per i due elementi.
    return Column(
      // Allinea i figli a sinistra.
      crossAxisAlignment: CrossAxisAlignment.start,
      // Figli della colonna.
      children: [
        // Testo della categoria.
        Text(info.categoria, style: theme.textTheme.bodyMedium),
        // Riga per icona e testo di disponibilità.
        Row(
          // Figli della riga.
          children: [
            // Icona di disponibilità.
            Icon(
              // Sceglie l'icona in base allo stato.
              prodotto.inStock ? Icons.check_circle : Icons.cancel,
              // Dimensione dell'icona.
              size: 16,
              // Colore dell'icona.
              color: prodotto.inStock
                  ? customColors.stockAvailable
                  : customColors.stockUnavailable,
            ),
            // Spazio orizzontale.
            const SizedBox(width: 4),
            // Testo della disponibilità.
            Text(
              // Contenuto testuale.
              info.disponibilita,
              // Stile del testo.
              style: theme.textTheme.bodySmall?.copyWith(
                // Colore che cambia in base alla disponibilità.
                color: prodotto.inStock
                    ? customColors.stockAvailable
                    : customColors.stockUnavailable,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Metodo che costruisce il widget del prezzo.
  Widget _buildPriceWidget(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Ottiene i colori personalizzati.
    final customColors = theme.extension<AppColorExtension>()!;
    // Colonna per gestire i prezzi (normale e scontato).
    return Column(
      // Allinea i prezzi a destra.
      crossAxisAlignment: CrossAxisAlignment.end,
      // Figli della colonna.
      children: [
        // Se c'è un prezzo scontato...
        if (prodotto.prezzoScontato != null) ...[
          // ...mostra il prezzo normale barrato.
          Text(
            // Prezzo formattato.
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
            // Stile del testo.
            style: theme.textTheme.bodySmall?.copyWith(
              // Aggiunge la linea barrata.
              decoration: TextDecoration.lineThrough,
              color: theme.textTheme.bodySmall?.color?.withAlpha(
                (255 * 0.6).round(),
              ),
            ),
          ),
          // E mostra il prezzo scontato in evidenza.
          Text(
            // Prezzo scontato formattato.
            PrezzoFormatter.formatPrezzo(prodotto.prezzoScontato!),
            // Stile del testo.
            style: theme.textTheme.bodyMedium?.copyWith(
              // Colore di "sconto" (rosso in questo caso).
              color: customColors.stockUnavailable,
              // Grassetto.
              fontWeight: FontWeight.bold,
            ),
          ),
          // Altrimenti...
        ] else
          // ...mostra solo il prezzo normale.
          Text(
            // Prezzo formattato.
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
            // Stile del testo.
            style: theme.textTheme.bodyMedium?.copyWith(
              // Grassetto.
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // Metodo che costruisce il "chip" delle varianti.
  Widget _buildVariantsChip(BuildContext context) {
    final theme = Theme.of(context);
    // Container per il chip.
    return Container(
      // Padding interno.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      // Decorazione del container.
      decoration: BoxDecoration(
        // Sfondo a gradiente.
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
            Theme.of(context).primaryColor.withAlpha((255 * 0.05).round()),
          ],
        ),
        // Angoli arrotondati.
        borderRadius: BorderRadius.circular(15),
        // Bordo.
        border: Border.all(
          // Colore del bordo.
          color: Theme.of(context).primaryColor.withAlpha((255 * 0.3).round()),
        ),
      ),
      // Riga per icona e testo.
      child: Row(
        // Adatta la dimensione al contenuto.
        mainAxisSize: MainAxisSize.min,
        // Figli della riga.
        children: [
          // Icona.
          Icon(Icons.palette, size: 14, color: Theme.of(context).primaryColor),
          // Spazio.
          const SizedBox(width: 4),
          // Testo con il numero di varianti.
          Text(
            // Contenuto testuale.
            '${prodotto.varianti.length}',
            // Stile del testo.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              // Grassetto.
              fontWeight: FontWeight.bold,
              // Colore del testo.
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget per i dettagli del prodotto.
class _ProductDetailsWidget extends StatelessWidget {
  // Controller della logica.
  final ProdottiGestioneController controller;
  // Callback per aggiornare la UI.
  final VoidCallback onStateChanged;

  // Costruttore.
  const _ProductDetailsWidget({
    required this.controller,
    required this.onStateChanged,
  });

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il prodotto selezionato (non può essere nullo qui, altrimenti questo widget non verrebbe mostrato).
    final prodotto = controller.prodottoSelezionato!;
    // Container di sfondo.
    return Container(
      // Colore di sfondo.
      color: Theme.of(context).scaffoldBackgroundColor,
      // SingleChildScrollView permette lo scrolling se il contenuto supera l'altezza dello schermo.
      child: SingleChildScrollView(
        // Padding attorno a tutto il contenuto.
        padding: const EdgeInsets.all(16),
        // Colonna per disporre le sezioni di dettaglio.
        child: Column(
          // Allinea i figli a sinistra.
          crossAxisAlignment: CrossAxisAlignment.start,
          // Figli della colonna.
          children: [
            // Header con immagine e nome.
            _ProductHeader(controller: controller),
            // Spazio.
            const SizedBox(height: 20),
            // Card con le informazioni principali.
            _ProductInfoCard(prodotto: prodotto),
            // Spazio.
            const SizedBox(height: 20),
            // Card con la lista delle varianti.
            _ProductVariantsCard(
              controller: controller,
              onStateChanged: onStateChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget per l'header del pannello dei dettagli.
class _ProductHeader extends StatelessWidget {
  // Controller.
  final ProdottiGestioneController controller;

  // Costruttore.
  const _ProductHeader({required this.controller});

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Controlla se il tema è scuro.
    final isDark = theme.brightness == Brightness.dark;
    // Ottiene il prodotto selezionato.
    final prodotto = controller.prodottoSelezionato!;
    // Container principale per l'header.
    return Container(
      // Decorazione.
      decoration: BoxDecoration(
        // Sfondo a gradiente.
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.cardColor,
                  Theme.of(
                    context,
                  ).primaryColor.withAlpha((255 * 0.05).round()),
                ]
              : [
                  theme.cardColor,
                  Theme.of(
                    context,
                  ).primaryColor.withAlpha((255 * 0.02).round()),
                ],
          // Punto di inizio.
          begin: Alignment.topCenter,
          // Punto di fine.
          end: Alignment.bottomCenter,
        ),
        // Angoli arrotondati.
        borderRadius: BorderRadius.circular(16),
        // Ombra.
        boxShadow: [
          // Definizione dell'ombra.
          BoxShadow(
            // Colore.
            color: Theme.of(
              context,
            ).primaryColor.withAlpha((255 * 0.1).round()),
            // Sfocatura.
            blurRadius: 15,
            // Spostamento.
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // Padding interno.
      child: Padding(
        // Valore del padding.
        padding: const EdgeInsets.all(20),
        // Colonna per immagine, nome e descrizione.
        child: Column(
          // Figli.
          children: [
            // Widget dell'immagine.
            _ProductImage(controller: controller),
            // Spazio.
            const SizedBox(height: 20),
            // Testo del nome.
            Text(
              // Contenuto.
              prodotto.nome,
              // Stile.
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              // Allineamento del testo.
              textAlign: TextAlign.center,
            ),
            // Spazio.
            const SizedBox(height: 8),
            // Container per la descrizione breve (stile "pillola").
            Container(
              // Padding interno.
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Decorazione.
              decoration: BoxDecoration(
                // Colore di sfondo.
                color: Theme.of(context).primaryColor.withAlpha(
                  isDark ? (255 * 0.15).round() : (255 * 0.1).round(),
                ),
                // Angoli arrotondati.
                borderRadius: BorderRadius.circular(20),
                // Bordo.
                border: Border.all(
                  // Colore del bordo.
                  color: Theme.of(
                    context,
                  ).primaryColor.withAlpha((255 * 0.3).round()),
                ),
              ),
              // Testo della descrizione breve.
              child: Text(
                // Contenuto.
                prodotto.descrizioneBreve,
                // Stile.
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).primaryColor.withAlpha((255 * 0.8).round()),
                ),
                // Allineamento.
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget per l'immagine del prodotto.
class _ProductImage extends StatelessWidget {
  // Controller.
  final ProdottiGestioneController controller;

  // Costruttore.
  const _ProductImage({required this.controller});

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Controlla se il tema è scuro.
    final isDark = theme.brightness == Brightness.dark;
    // Ottiene l'URL dell'immagine corrente.
    final imageUrl = controller.getCurrentImageUrl();

    // AnimatedSwitcher anima il cambio del suo figlio.
    return AnimatedSwitcher(
      // Durata dell'animazione.
      duration: const Duration(milliseconds: 300),
      // Il figlio del widget.
      child: Container(
        // La chiave univoca. Quando cambia, l'animazione parte.
        key: ValueKey(imageUrl),
        // La larghezza è impostata a infinito per occupare tutto lo spazio orizzontale.
        width: double.infinity,
        // Altezza fissa.
        height: 180,
        // Decorazione del container.
        decoration: BoxDecoration(
          // Angoli arrotondati.
          borderRadius: BorderRadius.circular(16),
          // Bordo.
          border: Border.all(
            // Colore del bordo.
            color: Theme.of(
              context,
            ).primaryColor.withAlpha((255 * 0.3).round()),
            // Spessore del bordo.
            width: 2,
          ),
          // Ombra.
          boxShadow: [
            // Definizione dell'ombra.
            BoxShadow(
              // Colore.
              color: Theme.of(
                context,
              ).primaryColor.withAlpha((255 * 0.2).round()),
              // Sfocatura.
              blurRadius: 10,
              // Spostamento.
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect applica gli angoli arrotondati al suo figlio (l'immagine).
        child: ClipRRect(
          // Raggio degli angoli.
          borderRadius: BorderRadius.circular(14),
          // Image.network carica un'immagine da un URL.
          child: Image.network(
            // L'URL da cui caricare l'immagine.
            imageUrl,
            // Adatta l'immagine per coprire l'intero spazio (tagliandola se necessario).
            fit: BoxFit.cover,
            // Funzione builder chiamata se si verifica un errore durante il caricamento.
            errorBuilder: (_, __, ___) => Container(
              // Sfondo a gradiente per la casella di errore.
              decoration: BoxDecoration(
                // Gradiente.
                gradient: LinearGradient(
                  // Colori del gradiente a seconda del tema.
                  colors: isDark
                      ? [Colors.grey[800]!, Colors.grey[700]!]
                      : [Colors.grey[100]!, Colors.grey[50]!],
                ),
              ),
              // Icona che indica l'errore.
              child: Icon(
                // Icona specifica.
                Icons.image_not_supported,
                // Dimensione.
                size: 60,
                color: Theme.of(
                  context,
                ).primaryColor.withAlpha((255 * 0.5).round()),
              ),
            ),
            // Funzione builder chiamata durante il caricamento dell'immagine.
            loadingBuilder: (context, child, loadingProgress) {
              // Se il caricamento è completato, `loadingProgress` è nullo.
              if (loadingProgress == null) return child; // Mostra l'immagine.
              // Altrimenti, mostra un indicatore di progresso.
              return Container(
                // Sfondo a gradiente.
                decoration: BoxDecoration(
                  // Gradiente.
                  gradient: LinearGradient(
                    // Colori del gradiente a seconda del tema.
                    colors: isDark
                        ? [Colors.grey[800]!, Colors.grey[700]!]
                        : [Colors.grey[100]!, Colors.grey[50]!],
                  ),
                ),
                // Centra l'indicatore.
                child: Center(
                  // Indicatore di progresso circolare.
                  child: CircularProgressIndicator(
                    // Colore dell'indicatore.
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Card per le informazioni del prodotto.
class _ProductInfoCard extends StatelessWidget {
  // Dato del prodotto.
  final ProdottoWoo prodotto;

  // Costruttore.
  const _ProductInfoCard({required this.prodotto});

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Controlla se il tema è scuro.
    final isDark = theme.brightness == Brightness.dark;
    // Crea l'oggetto con le info formattate.
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    // Container per la card.
    return Container(
      // Decorazione.
      decoration: BoxDecoration(
        // Colore di sfondo.
        color: theme.cardColor,
        // Angoli arrotondati.
        borderRadius: BorderRadius.circular(16),
        // Ombra.
        boxShadow: [
          // Definizione dell'ombra.
          BoxShadow(
            // Colore dell'ombra.
            color: theme.shadowColor.withAlpha((255 * 0.1).round()),
            // Sfocatura.
            blurRadius: 10,
            // Spostamento.
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Padding interno.
      child: Padding(
        // Valore del padding.
        padding: const EdgeInsets.all(20),
        // Colonna per le informazioni.
        child: Column(
          // Allinea a sinistra.
          crossAxisAlignment: CrossAxisAlignment.start,
          // Figli.
          children: [
            // Riga per il titolo della card.
            Row(
              // Figli.
              children: [
                // Container per l'icona.
                Container(
                  // Padding.
                  padding: const EdgeInsets.all(8),
                  // Decorazione.
                  decoration: BoxDecoration(
                    // Colore di sfondo.
                    color: Theme.of(context).primaryColor.withAlpha(
                      isDark ? (255 * 0.15).round() : (255 * 0.1).round(),
                    ),
                    // Angoli arrotondati.
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Icona.
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                // Spazio.
                const SizedBox(width: 12),
                // Testo del titolo.
                Text(
                  // Contenuto.
                  'Informazioni Prodotto',
                  // Stile.
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            // Spazio.
            const SizedBox(height: 16),
            // Riga per l'ID.
            _InfoRow(label: 'ID', value: displayInfo.id),
            // Riga per lo SKU.
            _InfoRow(label: 'SKU', value: displayInfo.sku),
            // Riga per la categoria.
            _InfoRow(label: 'Categoria', value: displayInfo.categoria),
            // Riga per la disponibilità.
            _InfoRow(label: 'Disponibilità', value: displayInfo.disponibilita),
            // Riga per il prezzo.
            _InfoRow(label: 'Prezzo', value: displayInfo.prezzo),
          ],
        ),
      ),
    );
  }
}

// Widget riutilizzabile per una riga di informazione (etichetta e valore).
class _InfoRow extends StatelessWidget {
  // L'etichetta della riga.
  final String label;
  // Il valore della riga.
  final String value;

  // Costruttore.
  const _InfoRow({required this.label, required this.value});

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Padding per la riga.
    return Padding(
      // Valore del padding.
      padding: const EdgeInsets.symmetric(vertical: 6),
      // Riga per disporre etichetta e valore.
      child: Row(
        // Allineamento verticale all'inizio.
        crossAxisAlignment: CrossAxisAlignment.start,
        // Figli della riga.
        children: [
          // Container per l'etichetta.
          SizedBox(
            // Larghezza fissa.
            width: 100,
            // Testo dell'etichetta.
            child: Text(
              // Aggiunge i due punti.
              '$label:',
              // Stile del testo.
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(
                  (255 * 0.8).round(),
                ),
              ),
            ),
          ),
          // Expanded per il valore.
          Expanded(
            // Container per il valore.
            child: Container(
              // Padding interno.
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              // Decorazione.
              decoration: BoxDecoration(
                // Colore di sfondo.
                color: Theme.of(
                  context,
                ).primaryColor.withAlpha((255 * 0.05).round()),
                // Angoli arrotondati.
                borderRadius: BorderRadius.circular(6),
                // Bordo.
                border: Border.all(
                  // Colore del bordo.
                  color: Theme.of(
                    context,
                  ).primaryColor.withAlpha((255 * 0.1).round()),
                ),
              ),
              // SelectableText permette all'utente di selezionare e copiare il testo.
              child: SelectableText(
                // Il valore da visualizzare.
                value,
                // Lo stile del testo.
                style: theme.textTheme.bodyMedium?.copyWith(
                  // Colore del testo.
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card per le varianti del prodotto.
class _ProductVariantsCard extends StatelessWidget {
  // Controller.
  final ProdottiGestioneController controller;
  // Callback.
  final VoidCallback onStateChanged;

  // Costruttore.
  const _ProductVariantsCard({
    required this.controller,
    required this.onStateChanged,
  });

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Ottiene il prodotto selezionato.
    final prodotto = controller.prodottoSelezionato!;

    // Container per la card.
    return Container(
      // Decorazione.
      decoration: BoxDecoration(
        // Colore di sfondo.
        color: theme.cardColor,
        // Angoli arrotondati.
        borderRadius: BorderRadius.circular(16),
        // Ombra.
        boxShadow: [
          // Definizione dell'ombra.
          BoxShadow(
            // Colore.
            color: theme.shadowColor.withAlpha((255 * 0.1).round()),
            // Sfocatura.
            blurRadius: 10,
            // Spostamento.
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Padding interno.
      child: Padding(
        // Valore del padding.
        padding: const EdgeInsets.all(20),
        // Colonna per il contenuto.
        child: Column(
          // Allinea a sinistra.
          crossAxisAlignment: CrossAxisAlignment.start,
          // Figli.
          children: [
            // Header della sezione varianti.
            _buildVariantsHeader(context, prodotto.varianti.length),
            // Spazio.
            const SizedBox(height: 16),
            // Se una variante è selezionata...
            if (controller.hasVarianteSelezionata) ...[
              // ...mostra il pulsante di reset.
              _buildResetButton(context),
              // Spazio.
              const SizedBox(height: 12),
            ],
            // Lista delle varianti.
            _buildVariantsList(context),
          ],
        ),
      ),
    );
  }

  // Metodo che costruisce l'header della card delle varianti.
  Widget _buildVariantsHeader(BuildContext context, int variantsCount) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Controlla se è scuro.
    final isDark = theme.brightness == Brightness.dark;
    // Riga per il titolo e il contatore.
    return Row(
      // Figli.
      children: [
        // Container per l'icona.
        Container(
          // Padding.
          padding: const EdgeInsets.all(8),
          // Decorazione.
          decoration: BoxDecoration(
            // Colore di sfondo.
            color: Theme.of(context).primaryColor.withAlpha(
              isDark ? (255 * 0.15).round() : (255 * 0.1).round(),
            ),
            // Angoli arrotondati.
            borderRadius: BorderRadius.circular(8),
          ),
          // Icona.
          child: Icon(
            Icons.palette,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        // Spazio.
        const SizedBox(width: 12),
        // Titolo.
        Text(
          // Contenuto.
          'Varianti Disponibili',
          // Stile.
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        // Spacer occupa lo spazio vuoto.
        const Spacer(),
        // Contatore delle varianti.
        Container(
          // Padding.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          // Decorazione.
          decoration: BoxDecoration(
            // Sfondo a gradiente.
            gradient: LinearGradient(
              // Colori.
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withAlpha((255 * 0.8).round()),
              ],
            ),
            // Angoli arrotondati.
            borderRadius: BorderRadius.circular(15),
          ),
          // Testo del contatore.
          child: Text(
            // Converte il numero in stringa.
            '$variantsCount',
            // Stile.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              // Colore.
              color: Theme.of(context).colorScheme.onPrimary,
              // Grassetto.
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Metodo che costruisce il pulsante per deselezionare una variante.
  Widget _buildResetButton(BuildContext context) {
    // Container per dare al pulsante larghezza piena.
    return SizedBox(
      // Larghezza massima.
      width: double.infinity,
      // Pulsante con bordo.
      child: OutlinedButton.icon(
        // Azione alla pressione.
        onPressed: () {
          // Deseleziona la variante nel controller.
          controller.selezionaVariante(null);
          // Aggiorna la UI.
          onStateChanged();
        },
        // Icona del pulsante.
        icon: const Icon(Icons.clear, size: 16),
        // Testo del pulsante.
        label: const Text('Mostra immagine principale'),
        // Stile del pulsante.
        style: OutlinedButton.styleFrom(
          // Colore del testo e dell'icona.
          foregroundColor: Theme.of(context).primaryColor,
          // Colore e spessore del bordo.
          side: BorderSide(color: Theme.of(context).primaryColor),
          // Forma del pulsante.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // Padding interno.
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Metodo che costruisce la lista delle varianti.
  Widget _buildVariantsList(BuildContext context) {
    // Ottiene il prodotto.
    final prodotto = controller.prodottoSelezionato!;
    // ListView.separated costruisce una lista con separatori tra gli elementi.
    return ListView.separated(
      // Si adatta all'altezza dei suoi figli.
      shrinkWrap: true,
      // Disabilita lo scrolling proprio (si scrolla con il genitore).
      physics: const NeverScrollableScrollPhysics(),
      // Numero di elementi.
      itemCount: prodotto.varianti.length,
      // Funzione che costruisce il separatore.
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      // Funzione che costruisce ogni elemento.
      itemBuilder: (context, index) {
        // Ottiene la variante corrente.
        final variante = prodotto.varianti[index];
        // Controlla se è selezionata.
        final isSelected = controller.isVarianteSelezionata(variante);
        // Ritorna il widget per il singolo item della variante.
        return _VariantItem(
          // Passa la variante.
          variante: variante,
          // Passa lo stato di selezione.
          isSelected: isSelected,
          // Passa la callback per il tocco.
          onTap: () {
            // Seleziona la variante toccata.
            controller.selezionaVariante(variante);
            // Aggiorna la UI.
            onStateChanged();
          },
        );
      },
    );
  }
}

// Widget per un singolo elemento nella lista delle varianti.
class _VariantItem extends StatelessWidget {
  // La variante da visualizzare.
  final VarianteWoo variante;
  // Flag che indica se è selezionata.
  final bool isSelected;
  // Callback per il tocco.
  final VoidCallback onTap;

  // Costruttore.
  const _VariantItem({
    required this.variante,
    required this.isSelected,
    required this.onTap,
  });

  // Metodo che costruisce l'interfaccia.
  @override
  Widget build(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Controlla se è scuro.
    final isDark = theme.brightness == Brightness.dark;
    // **INTEGRAZIONE TEMA**: Ottiene i colori personalizzati dall'estensione
    final customColors = theme.extension<AppColorExtension>()!;

    // InkWell per l'effetto al tocco.
    return InkWell(
      // Azione al tocco.
      onTap: onTap,
      // Raggio del ripple.
      borderRadius: BorderRadius.circular(12),
      // AnimatedContainer per animare i cambiamenti di stile.
      child: AnimatedContainer(
        // Durata dell'animazione.
        duration: const Duration(milliseconds: 200),
        // Padding interno.
        padding: const EdgeInsets.all(12),
        // **MODIFICA PRINCIPALE**: La decorazione ora usa i colori del tema.
        decoration: BoxDecoration(
          // Se selezionato, usa il colore 'variantSelectedBackground' dal tema.
          color: isSelected ? customColors.variantSelectedBackground : null,
          // Altrimenti, per lo stato non selezionato, usa un gradiente leggero.
          gradient: !isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [
                          theme.cardColor.withAlpha((255 * 0.5).round()),
                          theme.cardColor.withAlpha((255 * 0.3).round()),
                        ]
                      : [
                          Colors.grey[100]!,
                          Colors.grey[50] ?? Colors.grey[100]!
                        ],
                )
              : null, // Nessun gradiente se il colore solido è già impostato.
          // Angoli arrotondati.
          borderRadius: BorderRadius.circular(12),
          // Bordo che cambia se selezionato.
          border: Border.all(
            // Colore del bordo.
            color: isSelected
                ? Theme.of(context).primaryColor
                : theme.dividerColor,
            // Spessore del bordo.
            width: isSelected ? 2 : 1,
          ),
          // Ombra che appare solo se selezionato.
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withAlpha((255 * 0.2).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        // Riga per il contenuto dell'item.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Se la variante ha un'immagine...
            if (variante.immagineUrl != null &&
                variante.immagineUrl!.isNotEmpty) ...[
              // ...mostra l'immagine.
              _buildVariantImage(context, isDark),
              // Spazio.
              const SizedBox(width: 12),
            ],
            // Info della variante (nome, SKU).
            Expanded(child: _buildVariantInfo(context)),
            // Prezzo e quantità della variante.
            _buildVariantPrice(context),
            // Se selezionato...
            if (isSelected) ...[
              const SizedBox(width: 8),
              _buildSelectedIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

// Widget per il cerchio colorato
  Widget _buildColorSwatch(BuildContext context) {
    // Ora il getter 'attributoColore' esiste e può essere usato.
    final colorAttr = variante.attributoColore;
    
    // Se non esiste un attributo colore per questa variante, non mostrare nulla.
    if (colorAttr == null || colorAttr.valore == null) {
      return const SizedBox.shrink();
    }

    final color = hexToColor(colorAttr.valore!);

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      // Aggiunge un segno di spunta se la variante è selezionata,
      // per migliorare la visibilità su colori simili.
      child: isSelected
          ? Icon(
              Icons.check,
              size: 16,
              // Sceglie un colore di contrasto (bianco o nero) per il segno di spunta.
              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
  }
  
 Widget _buildVariantInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Mostra il cerchio colorato PRIMA del testo.
        _buildColorSwatch(context),
        
        // La colonna per il testo occupa lo spazio rimanente.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Usa il getter 'nomeVisualizzabile' che abbiamo definito prima.
                variante.nomeVisualizzabile,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : theme.textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${variante.sku}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(
                    (255 * 0.7).round(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // Metodo che costruisce l'immagine thumbnail della variante.
  Widget _buildVariantImage(BuildContext context, bool isDark) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // Container per l'immagine.
    return Container(
      // Larghezza.
      width: 45,
      // Altezza.
      height: 45,
      // Decorazione.
      decoration: BoxDecoration(
        // Angoli arrotondati.
        borderRadius: BorderRadius.circular(8),
        // Bordo.
        border: Border.all(
          // Colore che cambia se selezionato.
          color: isSelected
              ? Theme.of(context).primaryColor
              : theme.dividerColor,
          // Spessore che cambia se selezionato.
          width: isSelected ? 2 : 1,
        ),
      ),
      // ClipRRect per applicare i bordi arrotondati all'immagine.
      child: ClipRRect(
        // Raggio.
        borderRadius: BorderRadius.circular(6),
        // Immagine da rete.
        child: Image.network(
          // URL.
          variante.immagineUrl!,
          // Adattamento.
          fit: BoxFit.cover,
          // Gestore di errore.
          errorBuilder: (_, __, ___) => Container(
            // Colore di sfondo.
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            // Icona di errore.
            child: Icon(
              Icons.image,
              size: 20,
              color: Theme.of(
                context,
              ).iconTheme.color?.withAlpha((255 * 0.5).round()),
            ),
          ),
        ),
      ),
    );
  }
  
  // Metodo che costruisce prezzo e quantità della variante.
  Widget _buildVariantPrice(BuildContext context) {
    // Ottiene il tema.
    final theme = Theme.of(context);
    // **INTEGRAZIONE TEMA**: Ottiene i colori personalizzati
    final customColors = theme.extension<AppColorExtension>()!;

    // Colonna allineata a destra.
    return Column(
      // Allineamento.
      crossAxisAlignment: CrossAxisAlignment.end,
      // Figli.
      children: [
        // Container stile "pillola" per il prezzo.
        Container(
          // Padding.
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          // **MODIFICA**: La decorazione del prezzo ora usa i colori del tema
          decoration: BoxDecoration(
            // Se selezionato, usa il colore primario per evidenza.
            // Altrimenti usa il 'priceBackground' definito nel tuo tema.
            color: isSelected
                ? Theme.of(context).primaryColor
                : customColors.priceBackground,
            // Angoli arrotondati.
            borderRadius: BorderRadius.circular(12),
          ),
          // Testo del prezzo.
          child: Text(
            // Prezzo formattato.
            PrezzoFormatter.formatPrezzo(variante.prezzo),
            // Stile.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  // Se non selezionato e il colore di sfondo è quello personalizzato,
                  // usa un colore di testo più scuro per una migliore leggibilità.
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : customColors.stockAvailable,
                ),
          ),
        ),
        // Spazio.
        const SizedBox(height: 4),
        // Riga per icona e quantità.
        Row(
          // Adatta la dimensione al contenuto.
          mainAxisSize: MainAxisSize.min,
          // Figli.
          children: [
            // Icona inventario.
            Icon(
              // Icona.
              Icons.inventory,
              // Dimensione.
              size: 14,
              // Colore che cambia se selezionato.
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : theme.iconTheme.color?.withAlpha((255 * 0.7).round()),
            ),
            // Spazio.
            const SizedBox(width: 4),
            // Testo della quantità.
            Text(
              // Contenuto.
              '${variante.quantita}',
              // Stile.
              style: theme.textTheme.bodySmall?.copyWith(
                // Colore che cambia se selezionato.
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : theme.textTheme.bodySmall?.color?.withAlpha(
                        (255 * 0.7).round(),
                      ),
                // Grassetto se selezionato.
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Metodo che costruisce l'indicatore di selezione (cerchio con spunta).
  Widget _buildSelectedIndicator(BuildContext context) {
    // Container circolare.
    return Container(
      // Padding.
      padding: const EdgeInsets.all(4),
      // Decorazione.
      decoration: BoxDecoration(
        // Colore.
        color: Theme.of(context).primaryColor,
        // Forma.
        shape: BoxShape.circle,
      ),
      // Icona di spunta.
      child: Icon(
        // Icona.
        Icons.check,
        // Dimensione.
        size: 16,
        // Colore.
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}