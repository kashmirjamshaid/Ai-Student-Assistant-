class QuizQuestion {
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer; // 'A', 'B', 'C', or 'D'
  final String explanation;
  String selectedAnswer; // 'A', 'B', 'C', 'D' or empty if not answered yet

  QuizQuestion({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.explanation,
    this.selectedAnswer = '',
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'optionA': optionA,
        'optionB': optionB,
        'optionC': optionC,
        'optionD': optionD,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'selectedAnswer': selectedAnswer,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        optionA: json['optionA'] as String,
        optionB: json['optionB'] as String,
        optionC: json['optionC'] as String,
        optionD: json['optionD'] as String,
        correctAnswer: json['correctAnswer'] as String,
        explanation: json['explanation'] as String,
        selectedAnswer: (json['selectedAnswer'] ?? '') as String,
      );
}

class Quiz {
  final String topic;
  final List<QuizQuestion> questions;
  final DateTime timestamp;
  final int score; // total correct answers

  Quiz({
    required this.topic,
    required this.questions,
    required this.timestamp,
    required this.score,
  });

  int get totalQuestions => questions.length;
  int get correctAnswers => score;
  int get wrongAnswers => totalQuestions - score;
  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'questions': questions.map((q) => q.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'score': score,
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        topic: json['topic'] as String,
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        score: json['score'] as int,
      );
}
