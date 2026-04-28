# ResumeFit AI 🚀

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![OpenRouter](https://img.shields.io/badge/AI-GPT--4o--mini-412991?style=for-the-badge&logo=openai&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**AI-powered resume analyzer that scores your resume, matches keywords, and gives actionable feedback — personalized to any job description.**

</div>

---

## ✨ Features

- 📄 **PDF Upload** — Pick any resume PDF directly from your device
- 🤖 **AI Analysis** — GPT-4o-mini scores your resume and gives detailed feedback
- 🎯 **Job Description Match** — Paste a JD and get a tailored ATS score
- 🔑 **Keyword Matching** — Detects which keywords are present or missing
- 💪 **Strengths & Weaknesses** — Specific, actionable improvement tips
- 📊 **ATS Score (0–100)** — Know exactly how ATS-friendly your resume is
- ☁️ **Cloud History** — All analyses saved to Firestore, synced across devices
- 🔐 **Google Sign-In** — One-tap login with your Google account
- 📱 **Cross-Platform** — Android, iOS, and Web (Edge/Chrome)

---

## 📸 Screenshots

> *Add screenshots here*

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x + Dart |
| State Management | Riverpod |
| Authentication | Firebase Auth + google\_sign\_in v7 |
| Database | Cloud Firestore |
| AI Engine | OpenRouter API (GPT-4o-mini) |
| PDF Parsing | Syncfusion Flutter PDF |
| Config | flutter\_dotenv |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A [Firebase](https://console.firebase.google.com) project
- An [OpenRouter](https://openrouter.ai/keys) API key

---

### 1. Clone the Repository

```bash
git clone https://github.com/alokpal2904/ResumeFit-AI-resume-analyzer.git
cd ResumeFit-AI-resume-analyzer/resume_analyzer
```

---

### 2. Set Up Environment Variables

Create a `.env` file in the `resume_analyzer/` root:

```env
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

Get your free key at → [openrouter.ai/keys](https://openrouter.ai/keys)

---

### 3. Set Up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com) → Create a project
2. Enable **Authentication** → Sign-in Methods → Enable:
   - Email/Password
   - Google
3. Enable **Firestore Database** → Start in test mode
4. Add your apps (Android + iOS + Web) and download config files:
   - Android → `google-services.json` → place in `android/app/`
   - iOS → `GoogleService-Info.plist` → place in `ios/Runner/`
   - Web → already embedded in `firebase_options.dart`
5. Run `flutterfire configure` to generate `firebase_options.dart`

---

### 4. Add SHA-1 Fingerprint (Android Google Sign-In)

```bash
keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA1** value → Firebase Console → Project Settings → Android App → Add fingerprint

> **Windows users:**
> ```powershell
> keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
> ```

---

### 5. Install Dependencies

```bash
flutter pub get
```

---

### 6. Run the App

```bash
# Android (USB or wireless)
flutter run

# Web
flutter run -d chrome

# iOS
flutter run -d iPhone
```

---

## 🔧 Firestore Security Rules

Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Each user can only read/write their own analyses
    match /users/{userId}/analyses/{analysisId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📁 Project Structure

```
resume_analyzer/
├── lib/
│   ├── main.dart                         # App entry point
│   ├── core/
│   │   ├── theme/                        # App colors, typography, shadows
│   │   └── router/                       # Named route configuration
│   ├── data/
│   │   ├── services/
│   │   │   ├── auth_service.dart         # Firebase Auth + Google Sign-In
│   │   │   ├── history_service.dart      # Firestore CRUD for analyses
│   │   │   ├── ai_service.dart           # OpenRouter API integration
│   │   │   └── pdf_service.dart          # PDF text extraction
│   ├── domain/
│   │   └── models/
│   │       ├── app_user.dart             # Auth user model
│   │       └── resume_analysis.dart      # Analysis result model
│   └── presentation/
│       ├── providers/
│       │   └── providers.dart            # All Riverpod providers
│       ├── screens/
│       │   ├── auth/                     # Login / Register screens
│       │   ├── dashboard/               # Home screen with history list
│       │   └── detail/                  # Full analysis detail screen
│       └── widgets/                     # Shared UI components
├── .env                                 # API keys (git-ignored)
└── pubspec.yaml
```

---

## ☁️ Firestore Data Structure

```
users/
  └── {uid}/
      └── analyses/
          └── {analysisId}/
              ├── ats_score: 82
              ├── file_name: "resume.pdf"
              ├── analyzed_at: "2026-04-28T12:30:00.000Z"
              ├── summary: "Strong candidate..."
              ├── strengths: [...]
              ├── weaknesses: [...]
              ├── suggestions: [...]
              ├── keyword_matches: [...]
              └── job_description: "..."
```

---

## 📱 Platform Support

| Feature | Android | iOS | Web | Windows |
|---|---|---|---|---|
| Email/Password Auth | ✅ | ✅ | ✅ | ✅ |
| Google Sign-In | ✅ | ✅ | ✅ | ❌ |
| PDF Upload | ✅ | ✅ | ✅ | ✅ |
| AI Analysis | ✅ | ✅ | ✅ | ✅ |
| Firestore History | ✅ | ✅ | ✅ | ✅ |

> Windows support for Google Sign-In is not available via the `google_sign_in` package. Use Email/Password on Windows.

---

## 🔐 Environment Variables

| Variable | Description | Where to Get |
|---|---|---|
| `OPENROUTER_API_KEY` | API key for GPT-4o-mini | [openrouter.ai/keys](https://openrouter.ai/keys) |

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.x        # State management
  firebase_core: ^3.x           # Firebase base
  firebase_auth: ^5.x           # Authentication
  cloud_firestore: ^5.x         # Cloud database
  google_sign_in: ^7.x          # Google OAuth
  syncfusion_flutter_pdf: ^33.x # PDF parsing
  file_picker: ^9.x             # File selection
  flutter_dotenv: ^5.x          # .env support
  http: ^1.x                    # API calls
  uuid: ^4.x                    # Analysis IDs
  flutter_animate: ^4.x         # Animations
  iconsax: ^0.x                 # Icons
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Alok Pal**

[![GitHub](https://img.shields.io/badge/GitHub-alokpal2904-181717?style=flat&logo=github)](https://github.com/alokpal2904)

---

<div align="center">
  Made with ❤️ using Flutter & Firebase
</div>
