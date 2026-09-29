// inventory_movement_key.code.dart
//
// La chiave che tiene insieme le righe di una sola operazione.
//
// Un movimento non e' una riga: e' un insieme di righe. Un carico di trenta
// codici che l'operatore fa in un colpo solo e' un movimento, non trenta, e lo
// storico deve mostrarlo come uno. Il problema e' che l'app invia una richiesta
// per riga e non puo' creare l'intestazione prima di sapere quante richieste
// andranno a buon fine: potrebbe aprire un movimento vuoto.
//
// La soluzione e' che l'identita' dell'operazione viaggia con le richieste. Ogni
// riga porta la stessa chiave, e il backend crea l'intestazione con la prima
// che arriva e la riusa per le altre. Se una richiesta fallisce, l'operazione
// resta con le righe andate a buon fine: e' cio' che e' successo, e mostrarlo
// per intero sarebbe raccontare un carico che l'operatore non ha fatto.

/// Contatore delle chiavi emesse in questa sessione.
///
/// Serve a distinguere due invii partiti nello stesso millisecondo: il solo
/// timestamp non basterebbe, e la seconda chiave troverebbe la prima gia' presa
/// unendosi a un movimento altrui. Il contatore e' per sessione e non viene
/// salvato: se l'app si riavvia durante il millisecondo giusto la collisione
/// richiederebbe un millisecondo preciso e un riavvio in quello stesso
/// millisecondo.
int _movementKeySequence = 0;

/// Chiave di movimento per un invio che parte adesso.
///
/// Va chiamata una volta sola per invio, non una per riga: e' l'invio intero a
/// essere un movimento. Chiamarla per ogni riga produrrebbe un movimento per
/// prodotto, cioe' esattamente il contrario di quello che si vuole vedere
/// nello storico.
///
/// Il formato e' quello che MGWS accetta: una lettera all'inizio, poi lettere,
/// cifre, trattini e underscore. Non porta dentro nessun dato leggibile: e' un
/// identificativo di raggruppamento, non un numero d'ordine, e un operatore che
/// lo leggesse come un progressivo cercherebbe un ordine che non esiste.
String newInventoryMovementKey() {
  _movementKeySequence += 1;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  return 'app-$stamp-$_movementKeySequence';
}
