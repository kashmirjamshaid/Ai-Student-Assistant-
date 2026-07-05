import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/bookmark.dart';
import '../../models/quiz.dart';
import '../../services/storage_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _deleteBookmark(Bookmark bookmark) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final index = storage.getBookmarks().indexWhere((b) => b.id == bookmark.id);
    
    await storage.deleteBookmark(bookmark.id);
    setState(() {}); // trigger rebuild

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted '${bookmark.title}'"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () async {
              await storage.saveBookmark(bookmark);
              setState(() {});
            },
          ),
        ),
      );
    }
  }

  void _copyBookmarkContent(Bookmark bookmark) {
    String textToCopy = bookmark.content;
    if (bookmark.type == 'quiz') {
      try {
        final Quiz quiz = Quiz.fromJson(jsonDecode(bookmark.content) as Map<String, dynamic>);
        final buffer = StringBuffer();
        buffer.writeln("Quiz: ${quiz.topic}");
        buffer.writeln("Score: ${quiz.score}/${quiz.totalQuestions} (${quiz.percentage.toInt()}%)\n");
        for (int i = 0; i < quiz.questions.length; i++) {
          final q = quiz.questions[i];
          buffer.writeln("Q${i + 1}: ${q.question}");
          buffer.writeln("  A) ${q.optionA}");
          buffer.writeln("  B) ${q.optionB}");
          buffer.writeln("  C) ${q.optionC}");
          buffer.writeln("  D) ${q.optionD}");
          buffer.writeln("  Correct: ${q.correctAnswer}");
          buffer.writeln("  Explanation: ${q.explanation}\n");
        }
        textToCopy = buffer.toString();
      } catch (_) {}
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Content copied to clipboard")),
    );
  }

  void _shareBookmark(Bookmark bookmark) {
    // Share by copying to clipboard with a nice header (since we don't want extra packages)
    final text = "Check out my Study Notes on '${bookmark.title}' from Student Assistant App:\n\n${bookmark.content}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Link & notes copied! Ready to share.")),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Bookmark bookmark) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  bookmark.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                const SizedBox(height: 12.0),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text("Copy Content"),
                  onTap: () {
                    Navigator.pop(context);
                    _copyBookmarkContent(bookmark);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text("Share Study Note"),
                  onTap: () {
                    Navigator.pop(context);
                    _shareBookmark(bookmark);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text("Delete Bookmark", style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteBookmark(bookmark);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = Provider.of<StorageService>(context);
    final bookmarks = storage.getBookmarks();

    final filtered = bookmarks.where((b) {
      final matchesSearch = b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Saved Bookmarks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: "Search Bookmarks",
                  hintText: "Search by title or topic...",
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),

            // Bookmarks list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      itemBuilder: (context, index) {
                        final bookmark = filtered[index];
                        final dateStr = DateFormat('MMM d, yyyy').format(bookmark.timestamp);
                        final isQuiz = bookmark.type == 'quiz';

                        // Subtitle preview helper
                        String preview = "";
                        if (isQuiz) {
                          try {
                            final qData = Quiz.fromJson(jsonDecode(bookmark.content) as Map<String, dynamic>);
                            preview = "Quiz Score: ${qData.score}/${qData.totalQuestions} • ${qData.percentage.toInt()}% correct";
                          } catch (_) {
                            preview = "Saved Quiz Questions";
                          }
                        } else {
                          preview = bookmark.content;
                          // strip markdown links and headings for clean preview
                          preview = preview.replaceAll(RegExp(r'[#*`_\-\[\]\(\)]'), '');
                          if (preview.length > 80) {
                            preview = "${preview.substring(0, 77).trim()}...";
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Dismissible(
                            key: Key(bookmark.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28.0),
                            ),
                            onDismissed: (direction) => _deleteBookmark(bookmark),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.06),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                leading: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isQuiz 
                                        ? Colors.orange.withOpacity(0.1) 
                                        : Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isQuiz ? Icons.quiz_rounded : Icons.description_rounded,
                                    color: isQuiz ? Colors.orange : Colors.blue,
                                    size: 22.0,
                                  ),
                                ),
                                title: Text(
                                  bookmark.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4.0),
                                    Text(
                                      preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookmarkDetailScreen(bookmark: bookmark),
                                    ),
                                  ).then((_) => setState(() {}));
                                },
                                onLongPress: () => _showOptionsBottomSheet(context, bookmark),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 64.0,
              color: theme.disabledColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16.0),
            Text(
              _searchQuery.isNotEmpty ? "No matching bookmarks" : "No saved bookmarks yet",
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              _searchQuery.isNotEmpty
                  ? "Try adjusting your search terms."
                  : "Tap the Bookmark icon on chat notes or quizzes to save them for offline access.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail screen to view full bookmark content
class BookmarkDetailScreen extends StatelessWidget {
  final Bookmark bookmark;

  const BookmarkDetailScreen({super.key, required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuiz = bookmark.type == 'quiz';
    final dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(bookmark.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isQuiz ? "Saved Quiz Detail" : "Saved Study Notes",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: "Copy to Clipboard",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bookmark.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Copied content to clipboard")),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookmark.title,
                style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12.0,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: isQuiz
                    ? _buildQuizDetail(theme)
                    : Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: MarkdownBody(
                            data: bookmark.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                              p: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15.0,
                                height: 1.5,
                              ),
                              h1: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                                height: 1.8,
                              ),
                              h2: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizDetail(ThemeData theme) {
    try {
      final quiz = Quiz.fromJson(jsonDecode(bookmark.content) as Map<String, dynamic>);
      
      return Column(
        children: [
          // Score summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Score",
                      style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      "${quiz.score} / ${quiz.totalQuestions}",
                      style: const TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    "${quiz.percentage.toInt()}% Correct",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Review title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Review Answers",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Scrollable questions list
          Expanded(
            child: ListView.builder(
              itemCount: quiz.questions.length,
              itemBuilder: (context, index) {
                final q = quiz.questions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question ${index + 1}: ${q.question}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSavedOptionText(theme, q, 'A', q.optionA),
                          _buildSavedOptionText(theme, q, 'B', q.optionB),
                          _buildSavedOptionText(theme, q, 'C', q.optionC),
                          _buildSavedOptionText(theme, q, 'D', q.optionD),
                          const SizedBox(height: 12.0),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
                            ),
                            child: Text(
                              "Explanation: ${q.explanation}",
                              style: TextStyle(
                                fontSize: 12.0,
                                height: 1.3,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } catch (e) {
      return Center(
        child: Text("Error parsing quiz: $e"),
      );
    }
  }

  Widget _buildSavedOptionText(ThemeData theme, QuizQuestion question, String optionLetter, String optionText) {
    final isSelected = question.selectedAnswer == optionLetter;
    final isCorrect = question.correctAnswer == optionLetter;

    IconData? statusIcon;
    Color textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    FontWeight weight = FontWeight.normal;

    if (isCorrect) {
      textColor = AppColors.success;
      weight = FontWeight.bold;
      statusIcon = Icons.check_circle_rounded;
    } else if (isSelected) {
      textColor = AppColors.error;
      weight = FontWeight.bold;
      statusIcon = Icons.cancel_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (statusIcon != null) ...[
            Icon(statusIcon, size: 16.0, color: isCorrect ? AppColors.success : AppColors.error),
            const SizedBox(width: 6.0),
          ] else ...[
            const SizedBox(width: 22.0), // alignment offset for normal options
          ],
          Text(
            "$optionLetter) ",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(color: textColor, fontWeight: weight, fontSize: 13.0),
            ),
          ),
        ],
      ),
    );
  }
}
