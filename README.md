# Donatello Lab – Flutter App

**Donatello Lab** è un'app mobile che genera idee regalo personalizzate tramite un'esperienza guidata.

---

## 🧠 Filosofia
L'utente entra in una metafora narrativa dove "commissiona" un dono a Donatello, lo scultore. L'app guida l'utente attraverso uno **step-by-step narrativo** fino a generare suggerimenti di regalo tramite API.

---

## 🚀 Tecnologie principali

- **Flutter 3.22+**
- **Dart 3**
- **Riverpod 2** – state management
- **Go Router** – navigazione
- **Dio** – API client
- **flutter_localizations + intl** – supporto multilingua
- **Google Fonts** – Playfair + Inter
- **Build Runner / JSON Serializable** – modelli automatici
- **Secure Storage / Shared Preferences** – salvataggio token JWT

---

## 📦 Struttura progetto

```
lib/
├── main.dart                # entry point
├── app.dart                 # MaterialApp + router
├── theme/                   # tema dark rinascimentale
├── l10n/                    # localizzazione .arb
├── models/                  # Gift, Recipient, User, GiftRequest
├── screens/                 # schermate principali
├── widgets/                 # UI riutilizzabile
├── services/                # API, Auth
└── router/                  # GoRouter
```

---

## 🌍 Localizzazione

Lingua di default: `italiano (it)`  
File localizzazione: `lib/l10n/app_it.arb`

Per rigenerare i file:
```bash
flutter gen-l10n
```

---

## 🔗 Backend

L'app si connette a un backend Django REST (non incluso in questo repo).  
Consulta la `Postman Collection` per dettagli su:

- `/api/auth/`
- `/api/recipients/`
- `/api/generate-gift-ideas/`
- `/api/saved-gifts/`
- `/api/history/`

---

## 🧪 Comandi utili

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

---

## 🖼️ Assets

Le immagini si trovano in `assets/images/`  
Ricordati di dichiararle in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
```

---

## ✨ TODO futuri

- Notifiche push
- Condivisione delle idee regalo
- Wishlist pubblica
- Supporto per tema chiaro
- Traduzione inglese

---

## 👤 Autore

**Simone Diaco**  
Dominio personale: [simonediaco.com](https://simonediaco.com)  
Package identifier: `com.simonediaco.donatellolab`

---

## 📜 Licenza

Questo progetto è distribuito per uso personale e sperimentale.
