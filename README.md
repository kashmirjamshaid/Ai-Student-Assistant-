# 🎓 Student Assistant AI

An AI-powered Flutter application that helps students understand concepts, generate study notes, create quizzes, and save important conversations for future revision.

Built with **Flutter** and **Google Gemini AI**, this project is designed to be simple, beginner-friendly, and easy to customize.

---

## ✨ Features

### 🤖 AI Study Assistant

* Ask questions about any topic.
* Get clear and easy-to-understand explanations.
* AI responses include:

  * Topic Overview
  * Detailed Explanation
  * Bullet Points
  * Real-life Examples
  * Summary
  * Key Points
  * Memory Tricks

### 📝 AI Notes Generator

* Generate structured study notes instantly.
* Copy notes with one tap.
* Regenerate responses.
* Bookmark notes for future revision.

### 📚 Quiz Generator

Generate quizzes on any topic.

Each quiz includes:

* 10 Multiple Choice Questions (MCQs)
* Four answer options
* Correct answer
* Explanation for each question
* Final score
* Percentage result

### 🔖 Bookmarks

Save and manage:

* AI Chats
* Study Notes
* Generated Quizzes

Features include:

* Search
* Copy
* Share
* Delete
* Local storage

### 📖 History

Access your previous AI conversations and continue learning anytime.

### 🌙 Theme Support

* Light Mode
* Dark Mode

---

## 🛠 Tech Stack

* Flutter
* Dart
* Google Gemini AI
* Hive (or SharedPreferences)
* Material 3

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/kashmirjamshaid/Ai-Student-Assistant-.git
cd student-assistant-ai
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Add Your Gemini API Key

Open:

```text
lib/services/gemini_service.dart
```

Replace:

```dart
const String apiKey = "YOUR_GEMINI_API_KEY";
```

with your own Gemini API key.

### 4. Run the App

```bash
flutter run
```

You're all set! 🎉

---

## 📦 Packages Used

* google_generative_ai
* hive
* hive_flutter
* flutter_markdown
* intl
* shared_preferences (optional)

---

## 🤝 Contributing

Contributions are welcome! Feel free to fork the repository, improve the project, and submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

Developed with Flutter and Google Gemini AI to provide students with a simple, intelligent learning companion.

If you found this project helpful, consider giving it a ⭐ on GitHub!
