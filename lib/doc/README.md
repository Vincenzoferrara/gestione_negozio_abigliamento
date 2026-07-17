# Gestione Negozio Abbigliamento

Documentazione tecnica attuale del progetto, pensata per contributor e IA.

## Scopo

- descrivere lo stato reale del codice
- spiegare come funziona oggi l'app
- aiutare chi contribuisce a orientarsi nel repo
- evitare di cercare nella wiki personale per capire il comportamento corrente

## Percorso rapido

- [`README.md` globale](../../README.md) - download pubblici e link rapidi alle release
- `guida-utente.md` - uso quotidiano per chi lavora con l'app
- `mappa-moduli.md` - elenco compatto di tutte le aree disponibili
- `guida-sviluppatori.md` - architettura, integrazioni e punti chiave per chi sviluppa
- `installazione.md` - avvio rapido e requisiti
- `configurazione.md` - impostazioni principali dell'app
- `faq.md` - risposte rapide alle domande comuni
- `troubleshooting.md` - problemi tipici e rimedi
- `architettura.md` - panoramica tecnica dei moduli
- `integrazioni.md` - backend, login e servizi esterni
- `sicurezza.md` - gestione credenziali e regole base
- `glossario.md` - termini ricorrenti dell'app
- `flussi-operativi.md` - sequenze rapide per le attivita piu comuni

## Regole chiave

- `lib/doc` descrive lo stato attuale del codice, non il backlog
- `architettura.md` spiega come sono organizzati moduli, settings, login e integrazioni
- `guida-sviluppatori.md` spiega le regole pratiche di sviluppo e separazione dei file
- `configurazione.md` spiega dove stanno le impostazioni e come si dividono globali e di modulo

## Sintesi

- App Flutter per gestione negozio abbigliamento
- Login con JWT, WooCommerce API o smartcard
- Cassa tramite checkout MGWS e ordine WooCommerce
- MGWS per inventario, loyalty e integrazioni custom
- Download pubblici e link Obtainium stanno nel [`README.md` globale](../../README.md)
- Questa cartella descrive solo lo stato attuale del codice
