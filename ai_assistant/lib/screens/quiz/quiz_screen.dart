import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/quiz.dart';
import '../../models/bookmark.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _topicController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final PageController _pageController = PageController();

  bool _isLoading = false;
  String _errorMessage = "";
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  bool _quizCompleted = false;
  bool _isBookmarked = false;
  String _topic = "";

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a topic first")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _questions = [];
      _currentQuestionIndex = 0;
      _quizCompleted = false;
      _isBookmarked = false;
      _topic = topic;
    });

    try {
      final generatedQuestions = await _geminiService.generateQuiz(topic);
      setState(() {
        _questions = generatedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    }
  }

  void _selectOption(QuizQuestion question, String option) {
    if (question.selectedAnswer.isNotEmpty) return; // Answer locked

    setState(() {
      question.selectedAnswer = option;
    });
  }

  int _calculateScore() {
    return _questions.where((q) => q.selectedAnswer == q.correctAnswer).length;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }

  Future<void> _bookmarkQuiz() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final score = _calculateScore();
    final quiz = Quiz(
      topic: _topic,
      questions: _questions,
      timestamp: DateTime.now(),
      score: score,
    );

    final id = "quiz_${DateTime.now().millisecondsSinceEpoch}";
    final bookmark = Bookmark(
      id: id,
      type: 'quiz',
      title: "Quiz: $_topic",
      content: jsonEncode(quiz.toJson()),
      timestamp: DateTime.now(),
    );

    await storage.saveBookmark(bookmark);
    setState(() {
      _isBookmarked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quiz saved to Bookmarks")),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _isLoading
              ? _buildLoadingState(theme)
              : _errorMessage.isNotEmpty
                  ? _buildErrorState(theme)
                  : _questions.isEmpty
                      ? _buildInputState(theme)
                      : _quizCompleted
                          ? _buildResultsState(theme)
                          : _buildQuizPlayState(theme),
        ),
      ),
    );
  }

  // State 1: Input state (Enter topic)
  Widget _buildInputState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 64.0,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24.0),
            const Text(
              "Challenge Yourself",
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              "Generate a 10-question MCQ quiz on any subject instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32.0),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: "Quiz Topic",
                hintText: "e.g., Photosynthesis, Python basics, World War I",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20.0),
            CustomButton(
              label: "Generate Quiz",
              icon: Icons.auto_awesome,
              onPressed: _generateQuiz,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  // State 2: Loading state
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24.0),
          const Text(
            "Generating Quiz...",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            "Gemini is generating 10 premium multiple-choice questions on '$_topic'...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.0,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // State 3: Error state
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 64.0,
          ),
          const SizedBox(height: 16.0),
          const Text(
            "Oops! Something went wrong",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.0,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24.0),
          CustomButton(
            label: "Try Again",
            icon: Icons.refresh_rounded,
            onPressed: _generateQuiz,
          ),
        ],
      ),
    );
  }

  // State 4: Playing the Quiz (answering questions)
  Widget _buildQuizPlayState(ThemeData theme) {
    final question = _questions[_currentQuestionIndex];
    final totalQuestions = _questions.length;
    final answered = question.selectedAnswer.isNotEmpty;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12.0),
        // Progress Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${_currentQuestionIndex + 1} of $totalQuestions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: TextStyle(
                fontSize: 12.0,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4.0),
        ),
        const SizedBox(height: 20.0),

        // Questions viewport
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        q.question,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Options list
                    _buildOptionRow(theme, q, 'A', q.optionA),
                    _buildOptionRow(theme, q, 'B', q.optionB),
                    _buildOptionRow(theme, q, 'C', q.optionC),
                    _buildOptionRow(theme, q, 'D', q.optionD),

                    // Explanation Card
                    if (answered) ...[
                      const SizedBox(height: 16.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: q.selectedAnswer == q.correctAnswer
                              ? AppColors.success.withOpacity(0.06)
                              : AppColors.error.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: q.selectedAnswer == q.correctAnswer
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.selectedAnswer == q.correctAnswer ? "Correct! 🎉" : "Incorrect ❌",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: q.selectedAnswer == q.correctAnswer
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              "Explanation: ${q.explanation}",
                              style: TextStyle(
                                fontSize: 13.0,
                                height: 1.4,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30.0),
                  ],
                ),
              );
            },
          ),
        ),

        // Action Button
        if (answered) ...[
          CustomButton(
            label: _currentQuestionIndex == totalQuestions - 1 ? "Finish Quiz" : "Next Question",
            icon: Icons.arrow_forward_rounded,
            onPressed: _nextQuestion,
            width: double.infinity,
          ),
          const SizedBox(height: 16.0),
        ],
      ],
    );
  }

  Widget _buildOptionRow(ThemeData theme, QuizQuestion question, String optionLetter, String optionText) {
    final answered = question.selectedAnswer.isNotEmpty;
    final isSelected = question.selectedAnswer == optionLetter;
    final isCorrect = question.correctAnswer == optionLetter;

    Color cardBgColor = theme.cardColor;
    Color borderColor = theme.dividerColor.withOpacity(0.1);
    Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    FontWeight textWeight = FontWeight.normal;

    if (answered) {
      if (isCorrect) {
        // Correct answer highlighted in green
        cardBgColor = AppColors.success.withOpacity(0.12);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        textWeight = FontWeight.bold;
      } else if (isSelected) {
        // Tapped wrong answer highlighted in red
        cardBgColor = AppColors.error.withOpacity(0.12);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        textWeight = FontWeight.bold;
      } else {
        // Unselected options are greyed out slightly
        textColor = textColor.withOpacity(0.4);
      }
    } else {
      if (isSelected) {
        // Selected before answer is submitted (shouldn't happen since we lock on tap immediately)
        borderColor = theme.colorScheme.primary;
        textWeight = FontWeight.bold;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: answered ? null : () => _selectOption(question, optionLetter),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    width: 30.0,
                    height: 30.0,
                    decoration: BoxDecoration(
                      color: answered
                          ? (isCorrect
                              ? AppColors.success
                              : (isSelected ? AppColors.error : theme.dividerColor.withOpacity(0.05)))
                          : theme.colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      optionLetter,
                      style: TextStyle(
                        color: answered
                            ? (isCorrect || isSelected ? Colors.white : theme.textTheme.bodyMedium?.color?.withOpacity(0.5))
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.0,
                        fontWeight: textWeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // State 5: Results state
  Widget _buildResultsState(ThemeData theme) {
    final score = _calculateScore();
    final total = _questions.length;
    final pct = (score / total) * 100;
    
    // Custom messaging based on performance
    String congratsText;
    IconData congratsIcon;
    Color congratsColor;
    
    if (pct >= 80) {
      congratsText = "Exceptional Job! 🌟";
      congratsIcon = Icons.stars_rounded;
      congratsColor = AppColors.success;
    } else if (pct >= 50) {
      congratsText = "Good Effort! 👍";
      congratsIcon = Icons.thumb_up_rounded;
      congratsColor = theme.colorScheme.primary;
    } else {
      congratsText = "Keep Practicing! 💪";
      congratsIcon = Icons.psychology_rounded;
      congratsColor = Colors.orange;
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20.0),
            Icon(
              congratsIcon,
              size: 72.0,
              color: congratsColor,
            ),
            const SizedBox(height: 16.0),
            Text(
              congratsText,
              style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),

            // Performance Circular Gauge
            Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: congratsColor.withOpacity(0.12),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120.0,
                    height: 120.0,
                    child: CircularProgressIndicator(
                      value: score / total,
                      backgroundColor: theme.dividerColor.withOpacity(0.1),
                      color: congratsColor,
                      strokeWidth: 10.0,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${pct.toInt()}%",
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: congratsColor,
                        ),
                      ),
                      Text(
                        "$score / $total",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Stats breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem("Correct", "$score", AppColors.success),
                const SizedBox(width: 32.0),
                _buildStatItem("Wrong", "${total - score}", AppColors.error),
              ],
            ),
            const SizedBox(height: 36.0),

            // Action Buttons
            CustomButton(
              label: _isBookmarked ? "Quiz Saved" : "Save Quiz to Bookmarks",
              icon: _isBookmarked ? Icons.check_circle_rounded : Icons.bookmark_border_rounded,
              onPressed: _isBookmarked ? null : _bookmarkQuiz,
              width: double.infinity,
            ),
            const SizedBox(height: 12.0),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _questions = [];
                  _quizCompleted = false;
                  _topicController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              child: const Text(
                "Try Another Topic",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
