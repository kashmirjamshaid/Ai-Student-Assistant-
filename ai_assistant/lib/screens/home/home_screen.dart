import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/bookmark.dart';
import '../../services/storage_service.dart';
import '../../widgets/feature_card.dart';
import '../bookmarks/bookmarks_screen.dart'; // To open bookmark detail

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Bookmark? _recentBookmark;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  // Refresh recent activity whenever screen is displayed (e.g., when returning to Home)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecentActivity();
  }

  void _loadRecentActivity() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final bookmarks = storage.getBookmarks();
    setState(() {
      _recentBookmark = bookmarks.isNotEmpty ? bookmarks.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Simple greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Good Morning ☀️";
    } else if (hour < 17) {
      greeting = "Good Afternoon 🌤️";
    } else {
      greeting = "Good Evening 🌙";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Theme toggler
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: themeNotifier.isDarkMode ? Colors.amber : theme.colorScheme.primary,
                ),
                tooltip: "Toggle Theme",
                onPressed: () {
                  themeNotifier.toggleTheme();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4.0),
              const Text(
                "Welcome to Student Assistant",
                style: TextStyle(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24.0),

              // Feature Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.85,
                children: [
                  FeatureCard(
                    title: "AI Chat",
                    description: "Ask anything and generate notes.",
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/chat');
                      _loadRecentActivity(); // reload when back
                    },
                  ),
                  FeatureCard(
                    title: "Quiz Generator",
                    description: "Generate MCQs from any topic.",
                    icon: Icons.quiz_outlined,
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/quiz');
                      _loadRecentActivity();
                    },
                  ),
                  FeatureCard(
                    title: "Bookmarks",
                    description: "Saved notes and conversations.",
                    icon: Icons.bookmark_border_rounded,
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/bookmarks');
                      _loadRecentActivity();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28.0),

              // Recent Activity Section
              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildRecentActivityCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(ThemeData theme) {
    if (_recentBookmark == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 40.0,
              color: theme.disabledColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8.0),
            Text(
              "No recent activity",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              "Your bookmarked notes and quizzes will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final isQuiz = _recentBookmark!.type == 'quiz';
    final dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(_recentBookmark!.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.06),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            // Open full content
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookmarkDetailScreen(bookmark: _recentBookmark!),
              ),
            ).then((_) => _loadRecentActivity());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon matching the type
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isQuiz 
                        ? Colors.orange.withOpacity(0.1) 
                        : Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isQuiz ? Icons.quiz_rounded : Icons.chat_rounded,
                    color: isQuiz ? Colors.orange : Colors.blue,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                // Content preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recentBookmark!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        isQuiz ? "Quiz Result" : "Study Note",
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11.0,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.disabledColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple ThemeNotifier to manage dark/light state application-wide
class ThemeNotifier extends ChangeNotifier {
  final StorageService _storageService;
  late bool _isDarkMode;

  ThemeNotifier(this._storageService) {
    _isDarkMode = _storageService.getThemeMode();
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.setThemeMode(_isDarkMode);
    notifyListeners();
  }
}
