# Design System

## Scope

This project uses the existing Flutter `ThemeData` and `AppColorExtension` in `lib/theme/theme.dart` as the source of truth. Product-management UI follows a calm operational workstation style inspired by Material Design foundations and Fluent Design pane hierarchy. It is not a greenfield brand system.

## Extracted Tokens

### Color

- Primary action and emphasis: `ThemeData.primaryColor` / `colorScheme.primary` from the red seed.
- Tonal page background: `AppColorExtension.gradientStart` to `AppColorExtension.gradientEnd`, softened with `colorScheme.surface`.
- Command surfaces and panes: `colorScheme.surface`, `theme.cardColor`, `inputDecorationTheme.fillColor`.
- Subtle outlines: `theme.dividerColor` with reduced alpha, or `primaryColor` with low alpha for active states.
- Selection surfaces: `AppColorExtension.selectedCardBackground` for bulk selection and `variantSelectedBackground` for selected detail/variant rows.
- Price/readout surface: `AppColorExtension.priceBackground`.
- Stock status: `AppColorExtension.stockAvailable` and `stockUnavailable`.
- Semantic status: `AppColorExtension.successColor`, `warningColor`, and `errorColorStatus`.

### Spacing

- Dense inline controls: 8 px gaps.
- Command bars and compact cards: 12 px padding.
- Pane margins and standard cards: 16 px padding.
- Detail cards and hero cards: 20 px padding.
- Desktop page gutters: 16 px.

### Shape and Elevation

- Field radius: 8 px from `inputDecorationTheme`.
- Compact command chip/button radius: 12 px.
- Pane card radius: 18-20 px for workstation panels.
- Page panes: 24 px rounded corners on desktop.
- Shadows stay soft and low alpha; important state is shown with tonal fill and outline before elevation.

### Typography

- Use `theme.textTheme` only.
- Section headings use `titleMedium` or `titleLarge` with `FontWeight.w700`.
- Operational labels use `labelLarge`/`labelMedium` with increased weight where scanability matters.
- Metadata and helper copy use `bodySmall` with `AppColorExtension.subtitleColor` or reduced `onSurface` alpha.

## Products Workstation Pattern

- The Products screen uses a master/detail layout on desktop and a single-column flow on narrow screens.
- The master pane contains a command bar, filter chips, bulk-action bar, grid, and pagination inside one rounded operational surface.
- The detail pane uses a quieter pane background with cards for action header, media hero, read-only information, quick edit, variant filters, variants, and media mapping.
- All product actions remain visible as command controls: search, filters, stock toggle, sorting, import/export, columns, refresh, selection, delete, create/edit/delete.
- Row scanability uses chips for stock and publication status without changing IDs, raw values, sorting, filtering, or backend semantics.

## MGWS Quick Load Pattern

- `Carico rapido` uses a guided three-step flow: choose products/variants, set shared operation defaults, review and confirm.
- Quick-load location levels are capability-driven: an empty option list in `Impostazioni > Inventario` disables that level, hides its control, and excludes stale values from the MGWS payload.
- Product choice opens a dedicated catalog surface that reuses progressive product loading; variable parents expand to concrete variants and are not themselves selectable.
- Product rows show the product cover; variant rows show the variant cover with the product cover as fallback. Search covers name, SKU and barcode without requiring a separate scan mode.
- Selected simple products and variants use checkbox rows with a positive quantity field plus classic text fields for rack and shelf/level. Rack and shelf belong to the selected line so each variant can target a different physical position, but both remain optional.
- Warehouse and room remain shared selectable controls with explicit saved defaults. Warehouse, room, rack and shelf are serialized only when set; when they are all unset, MGWS selects the first valid warehouse in the permitted site scope and keeps room, rack and shelf empty.
- Compact layouts stack selection, defaults and summary in one scroll owner. Expanded layouts keep the selected lines and operation defaults side by side inside the same operational pane.
- Confirmation must state that multiple lines are sent sequentially, show line count and total quantity, and never imply an atomic backend batch.
- Use existing 8/12/16/20 px spacing tokens, `theme.textTheme`, tonal selected surfaces and semantic status colors. Do not introduce new hardcoded colors or decorative motion.

## Rules

- UI changes stay in `.gui.dart` files unless behavior makes a `.code.dart` change unavoidable.
- Do not hardcode unrelated colors in product UI; derive visual state from `ThemeData`, `ColorScheme`, and `AppColorExtension`.
- Extend this document before adding a new visual token or component language.
- Documentation in `lib/doc` describes current usage only, with no changelog or before/after wording.
