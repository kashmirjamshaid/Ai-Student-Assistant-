import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'services/storage_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/bookmarks/bookmarks_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage service
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(
    MultiProvider(
      providers: [
        // Provide storage service globally
        Provider<StorageService>.value(value: storageService),
        // Provide theme switcher globally
        ChangeNotifierProvider<ThemeNotifier>(
          create: (context) => ThemeNotifier(storageService),
        ),
      ],
      child: const StudentAssistantApp(),
    ),
  );
}

class StudentAssistantApp extends StatelessWidget {
  const StudentAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Light Theme Configuration
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.lightAccent,
              brightness: Brightness.light,
              primary: AppColors.lightAccent,
              secondary: AppColors.primaryGradientColors[0], // Blue
              background: AppColors.lightBg,
              surface: AppColors.lightCard,
            ),
            scaffoldBackgroundColor: AppColors.lightBg,
            cardColor: AppColors.lightCard,
            dividerColor: AppColors.lightBorder,
            
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.lightBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: AppColors.lightTextPrimary,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
              bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.lightCard,
              labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
              hintStyle: TextStyle(color: AppColors.lightTextSecondary.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.lightAccent, width: 2.0),
              ),
            ),
          ),
          
          // Dark Theme Configuration
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkAccent,
              brightness: Brightness.dark,
              primary: AppColors.darkAccent,
              secondary: AppColors.primaryGradientColors[1], // Purple
              background: AppColors.darkBg,
              surface: AppColors.darkCard,
            ),
            scaffoldBackgroundColor: AppColors.darkBg,
            cardColor: AppColors.darkCard,
            dividerColor: AppColors.darkBorder,
            
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
              bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.darkCard,
              labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
              hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.darkAccent, width: 2.0),
              ),
            ),
          ),
          
          // Application Routes Configuration
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/chat': (context) => const ChatScreen(),
            '/quiz': (context) => const QuizScreen(),
            '/bookmarks': (context) => const BookmarksScreen(),
          },
        );
      },
    );
  }
}
