# InvenMan

**InvenMan** is a modern inventory management app built with Flutter for small businesses, resellers, and independent sellers who need a simple but practical way to manage stock, sales, warranties, and installment-based transactions.

The app is designed around real daily business workflows. Users can add products, update stock, record sales, track profit, manage customer details, monitor installment payments, and review a full activity history from one place. The goal is to make inventory handling fast, clear, and reliable without overwhelming the user with unnecessary complexity.

InvenMan currently includes a stable **free version** focused on strong local inventory operations. A more advanced **premium version** is planned, with features such as user authentication, profile-based syncing across devices, analytics, cloud-backed data, and AI-assisted tools.

---

## Overview

InvenMan helps users manage the full lifecycle of items in inventory:

- add and organize products
- store pricing and supplier information
- attach images and warranty details
- sell products through direct or installment payments
- calculate and track profit
- maintain a searchable history of important actions

The app is built with a strong focus on usability, responsive design, and practical record keeping for real-world business usage.

---

## Core Features

### Inventory Management
- Add new items with:
  - name
  - category
  - description
  - cost price
  - selling price
  - quantity
  - supplier
  - warranty details
  - item images
- Edit existing inventory records
- Delete items from inventory
- View full item details in a clean dedicated details screen
- Track stock levels, including low-stock and out-of-stock cases
- Search and sort inventory for faster access

### Sales Management
- Record direct sales quickly
- Record installment-based sales
- Store customer details for each sale:
  - name
  - phone
  - address
- Automatically calculate profit per sale
- Preserve warranty information at the time of sale
- View full sales history with dedicated details screens

### Installment Tracking
- Create installment plans directly from sales
- Track:
  - total amount
  - down payment
  - financed amount
  - duration
  - monthly payment flow
  - remaining balance
- Support realistic payment behavior:
  - partial payments
  - overpayments
  - dynamic rebalancing of future dues
- Mark plans as active, overdue, or completed
- Monitor installment progress with detailed plan views
- Record and edit installment payments over time

### Warranty Tracking
- Store warranty duration by component or category
- Preserve sale warranty data for future reference
- View remaining warranty information for sold items
- Maintain warranty context across item and sales records

### History & Audit Trail
- Keep a timeline of major events across the app
- Track events such as:
  - item added
  - item edited
  - item deleted
  - item sold
  - installment plan created
  - installment payment recorded
- Search and sort history entries
- Review activity in grouped chronological format
- Designed to become a stronger audit trail as the app evolves

### Privacy & Visibility Controls
- Sensitive value hiding option for privacy
- Useful when showing the app to employees, partners, or customers without exposing internal pricing or profit data

### Responsive UI
- Built with Flutter for cross-platform support
- Designed to remain fluid across Android and Windows use cases
- Clean details screens for inventory, sales, installments, and history

---

## Current Version

The current free version focuses on **local-first inventory operations** and practical business tracking. It is intended to be stable, usable, and polished enough for everyday management tasks.

### Free Version Highlights
- local inventory database
- inventory CRUD
- direct sales
- installment sales
- profit tracking
- warranty tracking
- searchable history
- responsive item/sales/installment details
- privacy toggle for sensitive business values

---

## Planned Premium Version

The premium version is planned as a production-grade evolution of InvenMan, expanding from local inventory management into a connected business platform.

### Planned Premium Features
- user authentication
- user profiles
- sync inventory across multiple devices
- cloud-backed storage
- advanced analytics and insights
- richer reporting
- premium-only tools and workflows
- chatbot integration

The premium version will not simply add features on top of the free version. It is intended to be rebuilt more carefully with stronger architecture for sync, account-based data, and long-term scalability.

---

## Why InvenMan

InvenMan is built for users who need more than a basic stock list but do not want the overhead of large enterprise systems.

It is especially useful for:
- mobile and electronics resellers
- small retail businesses
- repair and resell businesses
- side-hustle sellers
- local businesses managing stock manually today
- businesses that sell products on installment terms

The app focuses on practical record keeping, business clarity, and future growth.

---

## Tech Stack

- **Flutter**
- **Dart**
- **SQLite / sqflite**
- **sqflite_common_ffi** for desktop database support

---

## Status

- Free version: **stable and actively refined**
- Premium version: **planned and under design**

---

## Vision

The long-term vision for InvenMan is to become a complete inventory and sales operations platform for small and growing businesses — starting with strong local inventory management and expanding into sync, analytics, automation, and intelligent assistance.

---

## License

This project is licensed under the **Apache License 2.0**.  
See the `LICENSE` file in the repository for full details.

---

## Author

**Fardous Nayeem**

- GitHub: [FardousNayeem](https://github.com/FardousNayeem/)
- LinkedIn: [Fardous Nayeem](https://www.linkedin.com/in/fardous-nayeem/)
