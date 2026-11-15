# Islamic Prayer & Hadith Companion ﷺ (Prototype)

A mobile application prototype built with **Flutter** and **SQLite** as a final course project. This app helps users stay connected to their daily prayers, read authentic sayings (Hadith) of Prophet Muhammad ﷺ, bookmark favorite narrations, and track their daily prayer habits offline.

## 📌 Project Status: Working Prototype
This repository contains the functional MVP (Minimum Viable Product) prototype demonstrating multi-screen navigation, astronomical prayer time calculation, and local relational database persistence (CRUD operations).

## ✨ Key Features & Screens
1. **Prayer Times & Daily Hadith Screen:** Calculates accurate daily prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) using the Egyptian General Authority of Survey calculation method, paired with a highlighted *Hadith of the Day*.
2. **Hadith Library Screen:** Displays a curated collection of authentic Hadiths (Arabic text and English translation) fetched directly from a local SQLite database, with one-tap bookmarking.
3. **Saved Favorites Screen:** Filters and displays user-bookmarked Hadiths stored persistently on the device, allowing quick removal and management.
4. **Daily Prayer Tracker Screen:** An interactive checklist that logs completed daily prayers into the local database to help users build consistent habits.

## 🛠️ Tech Stack
* **Framework:** Flutter (Dart)[cite: 1]
* **Database:** SQLite (`sqflite` & `path`) for offline local storage[cite: 1]
* **Prayer Calculation:** `adhan` Dart library
* **Date/Time Formatting:** `intl`

## 🗄️ Database Schema
The prototype initializes a local `islamic_app.db` SQLite database with two primary tables:
* `hadiths`: `id (INTEGER PK)`, `arabic (TEXT)`, `translation (TEXT)`, `isFavorite (INTEGER)`
* `prayer_logs`: `prayerName (TEXT PK)`, `isCompleted (INTEGER)`

## 🚀 How to Run Locally
1. Clone this repository:
   ```bash
   git clone https://github.com/Jetstream6/PrayerReminder_App.git
