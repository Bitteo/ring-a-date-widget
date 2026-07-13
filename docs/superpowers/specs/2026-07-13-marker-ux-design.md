# Marker UX Redesign — Design Spec

**Date:** 2026-07-13  
**Status:** Approved (brainstorming)  
**Scope:** Interaction design e UX per marcatori, home screen, placement flows

---

## Contesto e problema

L'implementazione attuale dei marcatori non soddisfa l'esperienza desiderata:

- Creazione/modifica tramite sheet modale con stepper +/- per il giorno
- Marcatori disconnessi dall'anteprima calendario (solo lista orizzontale di chip)
- Conflitto potenziale con il tap sulla griglia in modalità Manuale (muove gli anelli mobili)
- Home screen con sezione Marcatori sepolta nello scroll, lontana dall'anteprima

### Obiettivo

Simulare l'esperienza di un **calendario fisico perpetuo**: l'utente prende un anello colorato, lo posiziona su un giorno, e lo gestisce manualmente nel tempo. Nessun testo, nessuna notifica, nessuna logica automatica di rimozione o ricorrenza.

---

## Principi guida

1. **Manual-first** — tutto il ciclo di vita del marcatore è responsabilità dell'utente
2. **Calendario perpetuo** — la griglia mostra sempre giorni 1–31; i marcatori restano visibili sul numero scelto indipendentemente dal mese reale
3. **Canale di interazione separato** — i marcatori non usano il tap diretto sulla griglia (riservato agli anelli mobili in modalità Manuale)
4. **Rewarding** — snap, haptic e animazioni leggere al posizionamento e alla rimozione
5. **YAGNI** — niente toggle ricorrenza, niente auto-rimozione a fine mese, niente campi mese/anno

---

## Layout Home (approccio D — ibrido)

```
┌─────────────────────────────────────┐
│  [Piccolo | Medio | Grande]         │
│                                     │
│     ┌─────────────────────┐         │
│     │   ANTEPRIMA         │         │  ← ~45% schermo
│     │   CALENDARIO        │         │
│     └─────────────────────┘         │
│                                     │
│  PlacementModeBanner (condizionale) │
│                                     │
│  ── Marcatori ──────────── [+] ──   │
│  ○ ○ ●12 ●25                       │  ← MarkerTray, sempre visibile
│                                     │     sotto l'anteprima, fuori scroll
│  ── scroll ─────────────────────    │
│  Palette                            │
│  Modalità anelli                    │
│  Footer widget                      │
└─────────────────────────────────────┘
```

### Cambiamenti strutturali

| Prima | Dopo |
|-------|------|
| `markerSection` nello scroll | `MarkerTray` agganciata sotto `previewSection` |
| `MarkerEditorSheet` con stepper | `MarkerDrawer` + interazione diretta |
| Tap chip → sheet modale | Tap chip → placement mode; long press → context menu |

---

## Flussi di interazione

### Stato globale: Placement Mode

Quando un marcatore è attivo (tap nella tray o drag in corso):

| Comportamento | Placement mode ON | Placement mode OFF |
|---------------|-------------------|---------------------|
| Tap su data nell'anteprima | Posiziona il marcatore attivo | Manuale: muove anello corrente |
| Anelli mobili | Disabilitati | Normali |
| Anteprima | Bordo tratteggiato + date evidenziate | Normale |

Banner sottile: *"Tocca una data per posizionare"* — si chiude dopo posizionamento, annulla, o tap fuori.

```swift
// Logica di routing tap sulla griglia
if placementMode.isActive {
    onPegTap → placeMarker(on: day)
} else if mode == .manual {
    onPegTap → moveRing(ring, to: value)
}
// Automatico, fuori placement: nessuna azione
```

### Flusso A — Drag & drop (primario)

1. Utente prende un anello dalla `MarkerTray` (non posizionato o già posizionato)
2. Durante il drag: ghost ring segue il dito; le date sotto si illuminano leggermente
3. **Drop su data valida:** snap spring (0.35s, leggero overshoot) + haptic `.impact(.medium)` + chip tray aggiornato
4. **Drop fuori area:** anello torna nella tray con animazione elastic

Implementazione: `DragGesture` su `DraggableMarkerRing` + hit-testing date in `RingADateFace` via callback `onDateDrop`.

### Flusso B — Tap attiva → tap posiziona (alternativo)

1. Tap su anello nella tray → stato `.active` (bordo pulsante, scale 1.05)
2. Placement mode ON
3. Tap su data nell'anteprima → posiziona + haptic leggero
4. Tap su stesso anello o "Annulla" → esce dalla modalità

Utile su schermi piccoli e per accessibilità.

### Flusso C — Long press su data (secondario)

Solo su date **con marcatore già presente**:

1. Long press (0.4s) → `MarkerDrawer` dal basso (~40% schermo)
2. Drawer contiene anello grande centrato in alto (draggabile) + color picker + "Rimuovi"
3. Drag dell'anello dalla drawer verso l'anteprima = riposizionamento (nessun pulsante "Riposiziona")
4. Drop su nuova data → giorno aggiornato, drawer si chiude

### Flusso D — Gestione dalla tray

| Elemento | Tap | Long press |
|----------|-----|------------|
| Slot vuoto / anello non posizionato | Attiva placement mode | — |
| Chip posizionato `●12` | Attiva per riposizionare (tap-posiziona) | Context menu → "Elimina" |
| `+` | Crea nuovo anello non posizionato nella tray | — |

Pattern eliminazione identico alle palette custom (context menu con `Button("Elimina", role: .destructive)`).

### Eliminazione — due punti di accesso

| Dove | Come |
|------|------|
| Tray | Long press sul chip → context menu "Elimina" |
| Drawer | Pulsante "Rimuovi" → dissolve + haptic soft |

---

## MarkerDrawer

Sostituisce `MarkerEditorSheet`. Nessuno stepper numerico.

```
┌─────────────────────────────────┐
│                                 │
│           ┌─────┐               │
│           │  12 │  ← DraggableMarkerRing
│           └──○──┘     grande, centrato
│                                 │
│  Colore  [████████████]         │
│                                 │
│  [ Rimuovi ]                    │
└─────────────────────────────────┘
```

- L'anello in alto è lo stesso componente `DraggableMarkerRing` usato nella tray
- Drag verso anteprima = riposizionamento implicito
- Drop fuori area = torna al giorno originale
- Color picker modifica live (anteprima + widget)

---

## Feedback gratificante

| Momento | Feedback |
|---------|----------|
| Creazione anello (`+`) | Pop spring + haptic leggero |
| Drop riuscito | Snap + haptic medio + breve glow sull'anello (~0.3s) |
| Posizionamento via tap | Scale bounce sulla pastiglia |
| Rimozione | Dissolve verso tray + haptic soft |
| Cambio colore | Transizione fluida sull'anello in anteprima |

Nessun suono. Coerente con haptic e spring già usati per anelli mobili e mode picker.

---

## Modello dati

### `MarkerRing` aggiornato

```swift
struct MarkerRing: Identifiable, Codable, Equatable {
    var id: UUID
    var day: Int?        // nil = in tray, non ancora posizionato
    var colorHex: String
}
```

| Campo | Significato |
|-------|-------------|
| `day: nil` | Anello creato, in attesa di posizionamento (nella tray) |
| `day: 12` | Anello sulla pastiglia "12" |
| `colorHex` | Colore dell'anello |

**Nessun campo** `month`, `year`, `isRecurring`. Gestione 100% manuale.

### Calendario perpetuo

- La griglia mostra sempre giorni **1–31** (già implementato in `RingADateFace`: `if value <= 31`)
- Marcatore su giorno N → **sempre visibile** sulla pastiglia N, anche a febbraio sul 31
- Al cambio mese: marcatori **non si muovono, non scompaiono, non si resettano**
- Nessuna logica "giorno inesistente nel mese"

### Limite marcatori

Restare a **2** (`ThemeStorage.maxMarkerRings = 2`). Coerente con spazio visivo widget. Estendibile in futuro.

### Persistenza

- App Group (`ThemeStorage.markerRingsKey`) — invariata
- Widget ignora marcatori con `day == nil`
- Migrazione: marcatori esistenti con `day: Int` restano posizionati senza perdita dati

### Migrazione Codable

`day` passa da `Int` a `Int?`. I JSON esistenti con `day` intero decodificano correttamente. Nessuna migration script necessaria.

---

## Componenti SwiftUI

| Componente | File suggerito | Responsabilità |
|------------|----------------|----------------|
| `MarkerTray` | `ContentView.swift` o `MarkerTray.swift` | Barra orizzontale: chip, slot, `+` |
| `DraggableMarkerRing` | `DraggableMarkerRing.swift` | Anello con drag, ghost, stati idle/active/dragging/placed |
| `PlacementModeBanner` | `PlacementModeBanner.swift` | Hint testuale condizionale |
| `MarkerDrawer` | `MarkerDrawer.swift` | Sheet: anello draggabile + color picker + rimuovi |
| `RingADateFace` | `RingADateFace.swift` | Callback `onDateDrop`, `onDateLongPress`; hit-testing date in placement mode |
| `ThemeStore` | `ThemeStore.swift` | `activeMarkerID`, `placementMode`, `placeMarker(on:)`, `createMarker()`, `deleteMarker()` |

### Da rimuovere

- `MarkerEditorSheet`
- `MarkerEditorContext` (`.new` / `.edit`)
- Stepper giorno 1–31
- Sheet modale come flusso principale di creazione/modifica

### Stati `DraggableMarkerRing`

```
.idle     → chip normale nella tray
.active   → bordo pulsante, pronto al tap-posiziona
.dragging → ghost segue il dito, originale semi-trasparente
.placed   → chip con giorno (●12)
```

---

## `ThemeStore` — nuove API

```swift
@Published var activeMarkerID: UUID?
var placementMode: Bool { activeMarkerID != nil }

func createMarker(colorHex: String = lastUsedOrDefault)  // day: nil
func placeMarker(id: UUID, on day: Int)
func activateMarker(id: UUID)   // per tap-posiziona
func deactivatePlacement()
func deleteMarker(_ marker: MarkerRing)
```

`upsertMarker` resta per aggiornamento colore; `placeMarker` imposta `day`.

---

## `RingADateFace` — nuovi callback

```swift
var onDateDrop: ((Int, MarkerRing) -> Void)?      // day, marker being placed
var onDateLongPress: ((Int) -> Void)?              // day with existing marker
var placementHighlight: Bool = false               // evidenzia date come drop target
var isPlacementMode: Bool = false                  // disabilita ring tap routing
```

In placement mode, le celle data 1–31 accettano drop e tap per posizionamento. Gli anelli mobili (`slidingRing`) non rispondono al tap.

---

## Widget

Nessun cambiamento al widget per l'interazione (marcatori restano decorativi, `allowsHitTesting(false)`). Il widget continua a leggere `ThemeStorage.loadMarkerRings()` e renderizza marcatori con `day != nil`.

---

## Test

| Test | File |
|------|------|
| `MarkerRing` con `day: nil` encodes/decodes | `xcode_ring_a_dateTests.swift` |
| `placeMarker` imposta `day` e persiste | `xcode_ring_a_dateTests.swift` |
| Marcatori con `day: nil` esclusi dal rendering widget | test esistente o nuovo |
| Migrazione JSON legacy (`day` non opzionale) | `xcode_ring_a_dateTests.swift` |

---

## Fuori scope

- Aumento limite marcatori oltre 2
- Marcatori su weekday o mese (solo giorno del mese)
- Notifiche o promemoria testuali
- Interazione marcatori dal widget
- Undo/redo
- Validazione "giorno inesistente nel mese"

---

## Riepilogo decisioni

| Decisione | Scelta |
|-----------|--------|
| Layout home | Ibrido D: tray sotto anteprima, fuori scroll |
| Posizionamento primario | Drag & drop dalla tray |
| Posizionamento alternativo | Tap attiva → tap data |
| Modifica marcatore | Long press su data → drawer |
| Riposizionamento | Drag anello dalla drawer (no pulsante) |
| Eliminazione | Long press chip tray + pulsante drawer |
| Ricorrenza | Implicita, nessun toggle UI |
| Calendario | Perpetuo 1–31, marcatori sempre visibili |
| Limite | 2 marcatori |
| Stepper +/- | Rimosso |
