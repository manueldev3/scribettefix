import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'dart:convert';
import 'dart:math' show cos, pi, sin;

import 'package:scribettefix/core/helpers/database_helper.dart';

class MockTestPage extends StatefulWidget {
  final String title;
  final String content;

  const MockTestPage({super.key, required this.title, required this.content});

  @override
  MockTestPageState createState() => MockTestPageState();
}

class MockTestPageState extends State<MockTestPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> questions = [];
  List<String?> userAnswers = [];
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool isLoading = true;
  bool showResults = false;
  Map<String, int> tagPerformance = {};
  bool showTagPerformance = false;
  bool showCorrectAnswers = false;
  bool showIncorrectAnswers = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateMockTest();
  }

  Future<void> _loadOrGenerateMockTest() async {
    final existingTest = await _dbHelper.getMockTest(widget.title);
    if (existingTest != null) {
      setState(() {
        questions = List<Map<String, dynamic>>.from(existingTest['questions']);
        userAnswers = List.filled(questions.length, null);
        isLoading = false;
      });
    } else {
      await _generateMockTest();
    }
  }

  Future<void> _generateMockTest() async {
    final model = GenerativeModel(
      model: "gemini-1.5-pro",
      apiKey: 'AIzaSyDI7w8xqOS-8FrVzrHLTCdKTJilTd-pYh0',
    );

    try {
      final prompt = '''
Generate a mock test based on this title: ${widget.title} and content: ${widget.content}
Format the response as a JSON object with the following structure:
{
  "deck_name": "Test Title",
  "questions": [
    {
      "question": "Question text",
      "correct_answer": "Correct answer",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "tags": ["tag1", "tag2"]
    },
    // More questions...
  ]
}
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final regex = RegExp(r'json(.*?)', dotAll: true);
      final match = regex.firstMatch(response.text!);
      final jsonString = match?.group(1)?.trim() ?? '';
      final jsonResponse = jsonDecode(jsonString);

      setState(() {
        questions = List<Map<String, dynamic>>.from(jsonResponse['questions']);
        userAnswers = List.filled(questions.length, null);
        isLoading = false;
      });

      await _dbHelper.saveMockTest(widget.title, questions);
    } catch (e) {
      log('Error generating mock test: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedAnswer = null;
      });
    }
  }

  void _submitTest() {
    setState(() {
      showResults = true;
      _calculateTagPerformance();
    });
  }

  void _calculateTagPerformance() {
    tagPerformance.clear();
    for (int i = 0; i < questions.length; i++) {
      List<String> tags = List<String>.from(questions[i]['tags']);
      bool isCorrect = userAnswers[i] == questions[i]['correct_answer'];
      for (String tag in tags) {
        if (!tagPerformance.containsKey(tag)) {
          tagPerformance[tag] = 0;
        }
        tagPerformance[tag] = tagPerformance[tag]! + (isCorrect ? 1 : 0);
      }
    }
  }

  double _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i]['correct_answer']) {
        correctAnswers++;
      }
    }
    return (correctAnswers / questions.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (showResults) {
      final score = _calculateScore();
      return _buildResultsScreen(score);
    }

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? const Center(child: Text('No hay preguntas disponibles'))
              : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: const Color(0xFFA9ACBB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF262D47)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pregunta ${currentQuestionIndex + 1} de ${questions.length}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          questions[currentQuestionIndex]['question'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            questions[currentQuestionIndex]['options'].length,
                        itemBuilder: (context, index) {
                          final option =
                              questions[currentQuestionIndex]['options'][index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFE8EFFF), width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: RadioListTile<String>(
                                  title: Text(option),
                                  value: option,
                                  groupValue: userAnswers[currentQuestionIndex],
                                  onChanged: (value) {
                                    setState(() {
                                      userAnswers[currentQuestionIndex] = value;
                                    });
                                  },
                                  activeColor: const Color(0xFF262D47),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (currentQuestionIndex > 0)
                            ElevatedButton.icon(
                              onPressed: _previousQuestion,
                              icon: const Icon(
                                MingCuteIcons.mgc_left_line,
                                color: Colors.white,
                              ),
                              label: const Text('Anterior',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF262D47),
                              ),
                            ),
                          if (currentQuestionIndex < questions.length - 1)
                            ElevatedButton.icon(
                              style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                          const Color(0xFF262D47))),
                              iconAlignment: IconAlignment.end,
                              onPressed: _nextQuestion,
                              icon: const Icon(
                                MingCuteIcons.mgc_right_line,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Siguiente',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _submitTest,
                              icon: const Icon(MingCuteIcons.mgc_check_fill,
                                  color: Color(0xFF262D47)),
                              label: const Text(
                                'Finalizar',
                                style: TextStyle(
                                    color: Color(0xFF262D47),
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.white),
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                    side: const BorderSide(
                                        width: 2, color: Color(0xFF262D47)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(double score) {
    int correctAnswers = (score * questions.length / 100).round();
    int incorrectAnswers = questions.length - correctAnswers;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              const LinearProgressIndicator(
                value: 1,
                backgroundColor: Color(0xFFA9ACBB),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF262D47)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resultados',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF262D47)),
                        ),
                        const SizedBox(height: 20),
                        _buildScoreCircle(score),
                        const SizedBox(height: 40),
                        _buildScoreSummary(correctAnswers, incorrectAnswers),
                        const SizedBox(height: 20),
                        _buildTagPerformanceButton(),
                        if (showTagPerformance) _buildTagPerformance(),
                        const SizedBox(height: 20),
                        _buildRecommendations(score, questions),
                        const SizedBox(height: 20),
                        _buildAnswersReview(),
                        const SizedBox(height: 20),
                        _buildReturnButton(),
                      ],
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

  Widget _buildScoreCircle(double score) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: CustomPaint(
              painter: ScoreCirclePainter(score),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.round()}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              Text(
                _getScoreText(score),
                style: const TextStyle(fontSize: 20, color: Color(0xFF262D47)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFF4CAF60);
    if (score >= 75) return const Color(0xFF8BC34A);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 25) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getScoreText(double score) {
    if (score == 100) return '¡Perfecto!';
    if (score >= 90) return '¡Excelente!';
    if (score >= 75) return '¡Muy bien!';
    if (score >= 60) return 'Aprobado';
    if (score >= 25) return 'Necesita mejorar';
    return 'No aprobado';
  }

  Widget _buildScoreSummary(int correctAnswers, int incorrectAnswers) {
    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE8EFFF), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResultRow(
              'Respuestas correctas',
              correctAnswers,
              const Color(0xFF4CAF60),
            ),
            const Divider(color: Color(0xFFE8EFFF), thickness: 2),
            _buildResultRow(
              'Respuestas incorrectas',
              incorrectAnswers,
              const Color(0xFFF44336),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPerformanceButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          showTagPerformance = !showTagPerformance;
        });
      },
      icon: Icon(
          showTagPerformance
              ? MingCuteIcons.mgc_up_line
              : MingCuteIcons.mgc_down_line,
          color: Colors.white),
      label: Text(
        showTagPerformance
            ? 'Ocultar rendimiento por tema'
            : 'Mostrar rendimiento por tema',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF262D47),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
    );
  }

  Widget _buildTagPerformance() {
    // Contar las preguntas por etiqueta
    Map<String, int> tagQuestionCount = {};

    // Agrupar preguntas por su etiqueta
    for (var question in questions) {
      for (var tag in question['tags']) {
        if (!tagQuestionCount.containsKey(tag)) {
          tagQuestionCount[tag] = 0;
        }
        tagQuestionCount[tag] = tagQuestionCount[tag]! + 1;
      }
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE8EFFF), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendimiento por tema:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262D47)),
            ),
            const SizedBox(height: 10),
            ...tagPerformance.entries.map((entry) {
              // Aquí obtenemos la cantidad de preguntas por etiqueta
              int tagTotalQuestions = tagQuestionCount[entry.key] ?? 0;

              // Calcula el porcentaje para la etiqueta
              double percentage = (entry.value / tagTotalQuestions) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(entry.key,
                            style: const TextStyle(color: Color(0xFF262D47)))),
                    Text('${percentage.round()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF262D47))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: const Color(0xFFE8EFFF),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 60
                              ? const Color(0xFF4CAF60)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(
      double score, List<Map<String, dynamic>> questions) {
    String recommendation;

    // Lógica para recomendaciones personalizadas según el puntaje
    if (score == 100) {
      recommendation =
          '¡Excelente trabajo! Has dominado todos los temas. ¡Sigue así!';
    } else if (score >= 90) {
      recommendation =
          '¡Muy bien! Solo un poco más para llegar a la perfección.';
    } else if (score >= 75) {
      recommendation =
          'Buen trabajo. Sigue repasando los temas menos dominados.';
    } else if (score >= 60) {
      recommendation =
          'Estás en el camino, pero aún necesitas repasar varios temas.';
    } else if (score >= 25) {
      recommendation =
          'Te recomendamos repasar mucho más el material, especialmente los temas difíciles.';
    } else {
      recommendation =
          'Es importante estudiar y repasar más, sobre todo los temas que no dominas.';
    }

    // Clasificar y ordenar las áreas de rendimiento
    Map<String, List<String>> categorizedAreas = {
      '100%': [],
      '90-99%': [],
      '75-89%': [],
      '60-74%': [],
      '25-59%': [],
      '0-24%': [],
    };

    tagPerformance.forEach((tag, correctCount) {
      int totalQuestions =
          questions.where((q) => q['tags'].contains(tag)).length;
      double percentage = (correctCount / totalQuestions) * 100;

      if (percentage == 100) {
        categorizedAreas['100%']!.add(tag);
      } else if (percentage >= 90) {
        categorizedAreas['90-99%']!.add(tag);
      } else if (percentage >= 75) {
        categorizedAreas['75-89%']!.add(tag);
      } else if (percentage >= 60) {
        categorizedAreas['60-74%']!.add(tag);
      } else if (percentage >= 25) {
        categorizedAreas['25-59%']!.add(tag);
      } else {
        categorizedAreas['0-24%']!.add(tag);
      }
    });

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE8EFFF), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recomendaciones:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262D47)),
            ),
            const SizedBox(height: 10),
            Text(
              recommendation,
              style: const TextStyle(fontSize: 16, color: Color(0xFF262D47)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rendimiento por áreas:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262D47)),
            ),
            const SizedBox(height: 10),
            ...categorizedAreas.entries.map((entry) {
              if (entry.value.isEmpty) return Container();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(entry.key),
                    ),
                  ),
                  ...entry.value.map((tag) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF262D47))),
                      )),
                  const SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '100%':
        return const Color(0xFF4CAF60);
      case '90-99%':
        return const Color(0xFF8BC34A);
      case '75-89%':
        return const Color(0xFFFFC107);
      case '60-74%':
        return const Color(0xFFFF9800);
      case '25-59%':
        return const Color(0xFFFF5722);
      case '0-24%':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildAnswersReview() {
    return Column(
      children: [
        _buildAnswerSection(
          'Respuestas correctas',
          showCorrectAnswers,
          () => setState(() => showCorrectAnswers = !showCorrectAnswers),
          questions
              .asMap()
              .entries
              .where((entry) =>
                  userAnswers[entry.key] == entry.value['correct_answer'])
              .toList(),
          const Color(0xFF4CAF60),
        ),
        const SizedBox(height: 10),
        _buildAnswerSection(
          'Respuestas incorrectas',
          showIncorrectAnswers,
          () => setState(() => showIncorrectAnswers = !showIncorrectAnswers),
          questions
              .asMap()
              .entries
              .where((entry) =>
                  userAnswers[entry.key] != entry.value['correct_answer'])
              .toList(),
          const Color(0xFFF44336),
        ),
      ],
    );
  }

  Widget _buildAnswerSection(
      String title,
      bool isExpanded,
      VoidCallback onTap,
      List<MapEntry<int, Map<String, dynamic>>> filteredQuestions,
      Color color) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE8EFFF), width: 2),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF262D47))),
            trailing: Icon(
                isExpanded
                    ? MingCuteIcons.mgc_up_line
                    : MingCuteIcons.mgc_down_line,
                color: color),
            onTap: onTap,
          ),
          if (isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final entry = filteredQuestions[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFE8EFFF), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pregunta ${entry.key + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF262D47))),
                      const SizedBox(height: 8),
                      Text(
                          'Tu respuesta: ${userAnswers[entry.key] ?? 'No contestada'}',
                          style: const TextStyle(color: Color(0xFF262D47))),
                      Text(
                          'Respuesta correcta: ${entry.value['correct_answer']}',
                          style: const TextStyle(color: Color(0xFF262D47))),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(MingCuteIcons.mgc_left_line, color: Colors.white),
      label: const Text('Regresar al apunte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF262D47),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF262D47)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreCirclePainter extends CustomPainter {
  final double score;

  ScoreCirclePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = -pi / 2;
    const strokeWidth = 15.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Background circle
    paint.color = const Color(0xFFE8EFFF);
    canvas.drawCircle(center, radius, paint);

    // Score arcs
    final List<double> thresholds = [25, 60, 75, 90, 100];
    final List<Color> colors = [
      const Color(0xFFF44336),
      const Color(0xFFFF9800),
      const Color(0xFFFFC107),
      const Color(0xFF8BC34A),
      const Color(0xFF4CAF60),
    ];

    double startPercent = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (score > startPercent) {
        final endPercent = score.clamp(startPercent, thresholds[i]);
        final sweepAngle = (endPercent - startPercent) / 100 * 2 * pi;
        paint.color = colors[i];
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + (startPercent / 100 * 2 * pi),
          sweepAngle,
          false,
          paint,
        );
      }
      startPercent = thresholds[i];
    }

    // Division marks and labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = GoogleFonts.montserrat(
      color: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i <= 100; i += 25) {
      final angle = i / 100 * 2 * pi - pi / 2;
      final offset = Offset(
        center.dx + (radius + 15) * cos(angle),
        center.dy + (radius + 15) * sin(angle),
      );

      // Draw division mark
      canvas.drawLine(
        Offset(
            center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        Offset(center.dx + (radius + 10) * cos(angle),
            center.dy + (radius + 10) * sin(angle)),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );

      // Draw label
      textPainter.text = TextSpan(text: '$i%', style: labelStyle);
      textPainter.layout();
      textPainter.paint(canvas,
          offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
