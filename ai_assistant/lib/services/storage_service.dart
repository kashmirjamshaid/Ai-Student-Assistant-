import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/bookmark.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _bookmarksKey = "bookmarks_list";
  static const String _chatHistoryKey = "chat_history_list";
  static const String _themeKey = "is_dark_mode";

  // ================= THEME SETTINGS =================
  
  /// Gets the saved theme mode (true for dark, false for light).
  bool getThemeMode() {
    return _prefs.getBool(_themeKey) ?? false; // Defaults to light mode
  }

  /// Saves the theme mode.
  Future<void> setThemeMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  // ================= BOOKMARKS MANAGEMENT =================

  /// Retrieves the list of bookmarks sorted by date (latest first).
  List<Bookmark> getBookmarks() {
    final list = _prefs.getStringList(_bookmarksKey) ?? [];
    final bookmarks = list.map((item) => Bookmark.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
    // Sort by timestamp descending to ensure latest is always first
    bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return bookmarks;
  }

  /// Saves a new bookmark or updates an existing one.
  Future<void> saveBookmark(Bookmark bookmark) async {
    final bookmarks = getBookmarks();
    // Remove if there's already an item with the same ID
    bookmarks.removeWhere((item) => item.id == bookmark.id);
    // Add to the front of the list
    bookmarks.insert(0, bookmark);
    
    final serialized = bookmarks.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_bookmarksKey, serialized);
  }

  /// Deletes a bookmark by its ID.
  Future<void> deleteBookmark(String id) async {
    final bookmarks = getBookmarks();
    bookmarks.removeWhere((item) => item.id == id);
    
    final serialized = bookmarks.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_bookmarksKey, serialized);
  }

  // ================= CHAT HISTORY =================

  /// Gets the saved chat history of the active conversation.
  List<ChatMessage> getChatHistory() {
    final list = _prefs.getStringList(_chatHistoryKey) ?? [];
    return list.map((item) => ChatMessage.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  /// Saves the chat history of the active conversation.
  Future<void> saveChatHistory(List<ChatMessage> history) async {
    final serialized = history.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_chatHistoryKey, serialized);
  }

  /// Clears the chat history.
  Future<void> clearChatHistory() async {
    await _prefs.remove(_chatHistoryKey);
  }
}
