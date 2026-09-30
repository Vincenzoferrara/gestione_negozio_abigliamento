# Modules Map

## Home

The home screen uses a dockable layout on desktop and a simpler single-view flow on small screens. The top bar exposes the log button and login status. When authenticated, it shows the WordPress user avatar/name, `Online` state and account menu; otherwise it shows the login action.

## Available modules

- `Cashier` - POS workflow with explicit cash shift, barcode/manual product entry, cart lines, MGWS idempotent checkout, WooCommerce order creation and POS history
- `Products` - product catalog, filters, shared DataGridView, multi-selection, details panel, variants, images and MGWS stock readings
- `MGWS Inventory` - operational stock station with Add, Reconcile, Move and Movements modules
- `New Product` - product creation with original image selection and optional MGWS stock reconciliation after save
- `Coupons` - WooCommerce discounts and promotions
- `Orders` - order list and order details
- `Customers` - WooCommerce customer management
- `Suppliers` - MGWS supplier records when exposed by the active flow
- `Loyalty Cards` - MGWS points, card lookup, customer account and loyalty history
- `Reports` - labels, QR codes and printing flows
- `Dashboard` - WooCommerce analytics, charts and PDF/CSV exports for the active period
- `Settings` - backend, products, theme, AI, RFID, shortcuts and module settings
- `Updates` - desktop updates through Velopack and post-restart release notes
- `CalDAV` - calendars and contacts
- `Employees` - staff registry, optional WordPress user link and MGWS permissions for linked employees
- `RFID` - tag tests and scans
- `DataGridView` - technical test page for the shared table component

## Navigation notes

- Some modules are singletons and reopen the same tab
- Some modules can have multiple instances
- On mobile, the app shows one view at a time

## MGWS boundaries

- `Cashier` uses MGWS for POS checkout; WooCommerce stores the order created through MGWS
- POS history is local JSON/SharedPreferences data and remains separate from WooCommerce orders
- `Products` reads catalog and availability, and can trigger MGWS stock reconciliation during create/edit flows
- `MGWS Inventory` owns stock add, reconcile, move and movement-ledger reads
- `Loyalty Cards` uses MGWS for accounts, cards, points and history
- `Customers` remains a WooCommerce customer module; WordPress roles and capabilities are not managed there
- `Employees` uses MGWS employee records as the operational identity source
