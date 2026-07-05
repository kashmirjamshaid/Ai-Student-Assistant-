# Student Assistant 🎓

An interactive, AI-powered Flutter application designed to assist students in their learning journey. Leveraging the Google Gemini API, this application serves as a personal tutor, generating study guides, dynamic quizzes, and saving bookmarked materials.

## 🚀 Features

- **AI Study Companion**: Have a conversation with an expert teacher that explains complex concepts in a simple, structured format complete with summaries, key takeaways, and memory tricks.
- **Dynamic Quiz Generator**: Generates 10 multiple-choice questions (MCQs) on any academic topic of your choice. Real-time feedback and explanation for each question are provided.
- **Bookmarks & Saved Content**: Save and review important chats and study resources at any time.
- **Responsive Theme Modes**: Switch seamlessly between light and dark themes, saved locally using persistent storage.
- **Rich Markdown Support**: Study guides and answers are formatted using markdown rendering for readability.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.8)
- **AI Core**: [google_generative_ai](https://pub.dev/packages/google_generative_ai) (using `gemini-2.5-flash`)
- **State Management**: [provider](https://pub.dev/packages/provider)
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **UI Rendering**: [flutter_markdown](https://pub.dev/packages/flutter_markdown)
- **Utility**: [intl](https://pub.dev/packages/intl)

---

## 📂 Project Structure

```text
lib/
├── constants/          # Application styles, colors, and prompt configurations
│   ├── app_colors.dart
│   └── app_strings.dart
├── models/             # Data models for Chat, Quizzes, and Bookmarks
├── screens/            # UI screens and view components
│   ├── bookmarks/
│   ├── chat/
│   ├── home/
│   ├── quiz/
│   └── splash/
├── services/           # Services for storage and Gemini API integrations
│   ├── gemini_service.dart
│   └── storage_service.dart
└── main.dart           # App entry point, routing config, and dependency injection
```

---

## ⚙️ Getting Started & Setup

### 1. Prerequisites
Before running this application, make sure you have the following installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Dart SDK](https://dart.dev/get-started)
* A valid Gemini API Key from Google AI Studio.

### 2. Configure the Gemini API Key
To run the AI features, you must supply a Gemini API key.
1. Open the file: [gemini_service.dart](file:///d:/MobileAPPDev/Ai%20Assitant/lib/services/gemini_service.dart)
2. Locate the line:
   ```dart
   const String apiKey = "";
   ```
3. Paste your Gemini API key inside the quotes:
   ```dart
   const String apiKey = "YOUR_GEMINI_API_KEY_HERE";
   ```

### 3. Run the App
Navigate to the root directory and run the following commands:

```bash
# Fetch dependencies
flutter pub get

# Run on an emulator, connected device, or web browser
flutter run
```

---

## 📝 License

This project is configured for private use. Publishing to pub.dev is disabled.
