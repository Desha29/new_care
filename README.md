<div align="center">

# 🏥 New Care

**A Comprehensive Desktop Management System for Nursing Centers & Home Healthcare**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-orange.svg?logo=firebase)](https://firebase.google.com)
[![SQLite](https://img.shields.io/badge/SQLite-Local%20Storage-lightgrey.svg?logo=sqlite)](https://sqlite.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-lightgrey.svg)](#)

---

</div>

## 📝 About the Project
**New Care** is a massive Desktop application built with Flutter, entirely designed to serve nursing and medical care centers. The system offers a modern and responsive RTL (Right-to-Left) Arabic interface and effectively combines fast local storage (SQLite) with secure cloud storage (Firebase). It ensures a seamless workflow, keeping data synced whether your machine is online or offline.

---

## ✨ Key Features

*   **👥 Complete Patient Management:** Add, edit, real-time search, and manage full patient medical history and profiles.
*   **🩺 Treatment Cases & Visits Tracking:** Manage operations seamlessly (both In-Center and Home Visits), assign responsible nurses, track costs, and calculate eligible discounts.
*   **📦 Inventory Control:** Real-time tracking of medical supplies and equipment with automatic low-stock alerts and color-coded statuses.
*   **🖨️ Professional Printing & Invoicing:** Ability to generate and export case invoices natively in PDF format. Capable of printing A4 documents or through RTL-supported Thermal Printers.
*   **🔐 Advanced Role-Based Security:** System constraints backed by Firebase Rules ensuring full data security with different administrative powers (Super Admin, Admin, Nurse).
*   **📊 Insightful Dashboard:** Analyze work performance with a daily estimate of generated cases, total revenues, and general metrics visualized interactively via Pie, Bar, and Line charts.
*   **🔄 Smart Offline Sync:** Implemented a silent local persistence layer via SQLite to keep a backup and resynchronize automatically once internet connectivity is restored.

---

## 🛠️ Tech Stack & Architecture

This project is built adopting the **Feature-Driven Architecture & Clean Architecture principles** ensuring a highly maintainable, scalable, and testable source code structure.

*   **Framework:** Flutter Desktop (Windows / macOS)
*   **State Management:** BLoC / Cubit Pattern
*   **Backend Services:** Firebase (Firestore, Authentication, Remote Config)
*   **Local Database:** `sqflite_common_ffi` (Desktop Optimized)
*   **Printing Services:** `pdf` and `printing` packages
*   **Data Visualization:** `fl_chart`

---

## 🚀 Getting Started

### Prerequisites
1. Installed and configured Flutter SDK environments.
2. Enabled Flutter Desktop support: run `flutter config --enable-windows-desktop` (or macOS).
3. A pre-configured Firebase project with Authentication and Firestore enabled.

### Installation Steps

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/Desha29/new_care.git
   cd new_care
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Initialize Firebase Setup:**
   Setup your `google-services.json` and initialize the project locally by running the `flutterfire configure` CLI command.

4. **Verify Firestore Security Rules:**
   Copy the code block located in the `firestore.rules` file and paste it into the Rules tab found in your Firebase Console's Firestore database section.

5. **Run the App:**
   ```bash
   flutter run -d windows
   ```
   *(Swap `windows` with `macos` if developing on a Mac environment).*

---

## 📜 System User Roles
- **Super Administrator:** Grants absolute authorization to assign administrators and manipulate remote settings.
- **Administrator:** Regulates workflows, issues cases, tracks inventory reports, and controls full patient details.
- **Nurse:** Scope is limited uniquely to delegated cases, assigning used supplies, and marking their specific case workflows on closure.

---

**Made with passion to empower medical professionals! ❤️**