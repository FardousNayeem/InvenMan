# InvenMan

**InvenMan** is a modern inventory management app built with Flutter for small businesses, resellers, and independent sellers who need a simple but practical way to manage stock, sales, warranties, and installment-based transactions.

The app is designed around real daily business workflows. Users can add products, update stock, record sales, track profit, manage customer details, monitor installment payments, and review a full activity history from one place.

---

## Overview

InvenMan helps users manage the full lifecycle of items in inventory:

* add and organize products
* store pricing and supplier information
* attach images and warranty details
* sell products through direct or installment payments
* calculate and track profit
* maintain a searchable history of important actions

---

## Core Features

### Inventory Management

* Add, edit, and delete items
* Track stock levels and pricing
* Attach images and warranty details
* Search and sort inventory quickly

### Sales Management

* Record direct and installment-based sales
* Store customer details (name, phone, address)
* Automatically calculate profit
* Preserve warranty information at time of sale

### Installment Tracking

* Create installment plans from sales
* Track payments, balance, and progress
* Support partial and flexible payments
* Monitor active, overdue, and completed plans

### History & Audit Trail

* Full timeline of app activity
* Track all key operations (sales, edits, payments, etc.)
* Searchable and chronologically grouped

### Privacy Controls

* Hide sensitive values like cost and profit
* Useful for shared usage scenarios

### Responsive UI

* Optimized for Android and Windows
* Clean, structured detail screens across modules

---

## Data Management (New)

InvenMan now includes a **portable backup system**:

### Backup & Restore

* Export data as a single `.inv` backup file
* Includes:

  * full SQLite database
  * product images
  * installment documents
* Import backups to:

  * restore data
  * merge data across devices

### Data Deletion

* Secure “Delete All Data” option
* Requires confirmation input to prevent accidental loss
* Completely wipes local database and stored files

### Notes

* All data is stored locally in the free version
* Import currently **appends data** (does not replace existing data)
* Backups are fully portable across supported platforms

---

## Current Version

The free version focuses on **local-first inventory operations** with reliable data handling.

### Free Version Highlights

* local SQLite database
* inventory CRUD
* direct & installment sales
* profit tracking
* warranty tracking
* history tracking
* backup & restore system
* full data wipe controls
* responsive UI

---

## Planned Premium Version

The premium version will evolve InvenMan into a connected platform:

### Planned Features

* user authentication
* multi-device sync
* cloud backup & restore
* advanced analytics
* reporting tools
* AI-assisted features
* chatbot integration

The premium version will be built with a stronger architecture focused on sync, accounts, and scalability.

---

## Why InvenMan

InvenMan is designed for users who need practical business tracking without unnecessary complexity.

Ideal for:

* small retailers
* resellers
* installment-based sellers
* repair & resell businesses
* side-hustle businesses

---

## Tech Stack

* Flutter
* Dart
* SQLite (sqflite)
* sqflite_common_ffi (desktop support)

---

## Status

* Free version: **stable**
* Premium version: **planned**

---

## Vision

To evolve into a complete inventory and sales platform for small businesses — starting with strong local tools and expanding into sync, analytics, and intelligent assistance.

---

## License

Apache License 2.0
See `LICENSE` for details.

---

## Author

**Fardous Nayeem**

* GitHub: https://github.com/FardousNayeem/
* LinkedIn: https://www.linkedin.com/in/fardous-nayeem/
