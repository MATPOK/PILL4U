# PILL4U — Twój asystent zdrowia

Aplikacja mobilna wspierająca regularne przyjmowanie leków, zaprojektowana z myślą o maksymalnej dostępności i prostocie obsługi (m.in. dla seniorów).

## 🚀 O projekcie
PILL4U pozwala zarządzać harmonogramem leków, otrzymywać lokalne powiadomienia o porze dawki oraz śledzić skuteczność leczenia — również w trybie **offline**, z późniejszą synchronizacją z serwerem. Projekt studencki, realizowany w architekturze klient–serwer.

## 🛠 Stack technologiczny
| Warstwa | Technologia |
|---|---|
| Frontend | Flutter (Dart), wzorzec MVVM (`ChangeNotifier`) |
| Lokalna baza | SQLite (`sqflite`), architektura offline-first |
| Backend | Node.js (Express 5) |
| Baza serwera | SQLite (`sqlite3`) |
| Auth | JWT + `bcrypt`, token w `flutter_secure_storage` (Keystore/Keychain) |
| Powiadomienia | `flutter_local_notifications` + `timezone` |
| Dokumentacja API | Swagger UI (`/api-docs`) |
| CI | GitHub Actions (backend + frontend) |

## 🏗 Architektura
```
PILL4U/
├── frontend/                 # Aplikacja Flutter (MVVM)
│   └── lib/
│       ├── screens/          # Warstwa UI (widoki)
│       ├── viewmodels/       # Logika prezentacji (ChangeNotifier)
│       ├── services/         # ApiService (komunikacja REST)
│       ├── helpers/          # DatabaseHelper (SQLite), NotificationService,
│       │                     #   TokenStorage, SettingsController
│       └── models/           # Medication, HistoryEntry (fromJson/toJson/toApiJson)
├── backend/                  # API REST (Express + SQLite)
│   ├── index.js              # Endpointy + middleware JWT + CRON
│   ├── db.js                 # Schemat bazy
│   └── api.test.js           # Testy integracyjne (Jest + Supertest)
└── docs/                     # Wymagania, makiety, polityka prywatności
```

**Przepływ offline-first:** akcje użytkownika (dodanie/wzięcie/cofnięcie/usunięcie leku) zapisują się natychmiast w lokalnej bazie SQLite. `DashboardViewModel` cyklicznie i po każdej akcji synchronizuje zmiany z serwerem: wysyła kolejkę niezsynchronizowanych wpisów (`api_id IS NULL`) oraz kolejkę usunięć (`pending_delete` / soft-delete historii), a następnie pobiera aktualny stan z serwera.

## ▶️ Uruchomienie

### Wymagania
- Flutter SDK (kanał `stable`) + Android Studio / emulator,
- Node.js 20+.

### Backend
```bash
cd backend
cp .env.example .env          # uzupełnij JWT_SECRET (instrukcja generowania w pliku)
npm install
npm start                     # serwer na http://localhost:3000, Swagger: /api-docs
```
> Produkcyjny serwer: `https://pill4u.onrender.com/api`.

### Frontend
```bash
cd frontend
flutter pub get
flutter run                   # uruchomienie na emulatorze/urządzeniu
```
> Adres API ustawiany jest w `frontend/lib/services/api_service.dart` (`baseUrl`).

## ✅ Testy
```bash
# Backend — testy integracyjne API (Jest + Supertest)
cd backend && npm test

# Frontend — testy jednostkowe + analiza statyczna
cd frontend && flutter analyze && flutter test
```

## 🔐 Bezpieczeństwo
- Hasła hashowane `bcrypt`, autoryzacja przez JWT (ważność 24h).
- Token JWT przechowywany w szyfrowanym magazynie systemowym (`flutter_secure_storage`), nie w `SharedPreferences`.
- Sekrety (`JWT_SECRET`) trzymane w `.env`, który jest w `.gitignore` — używaj silnego, losowego sekretu (patrz `.env.example`).

## 👥 Zespół
- **Mateusz Pokrywka — Product Lead:** UX/UI, dokumentacja, makiety, polityka prywatności, refaktor MVVM.
- **Maciej Pereślucha — Frontend Developer:** Flutter (ekrany, ViewModele), lokalna baza SQLite, offline-first, powiadomienia.
- **Przemysław Potoczny — Backend Developer:** REST API, schemat bazy, Swagger, testy integracyjne, CI.

## 📄 Dokumentacja
Wymagania, makiety, polityka prywatności znajdują się w folderze `/docs`.
