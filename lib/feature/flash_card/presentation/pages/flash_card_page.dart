import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';

class FlashcardsPage extends StatefulWidget {
  final String title;
  final String content;

  const FlashcardsPage({super.key, required this.title, required this.content});

  @override
  FlashcardsPageState createState() => FlashcardsPageState();
}

class FlashcardsPageState extends State<FlashcardsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> flashcards = [];
  int currentIndex = 0;
  bool showingAnswer = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateFlashcards();
  }

  Future<void> _loadOrGenerateFlashcards() async {
    final existingFlashcards = await _dbHelper.getFlashcards(widget.title);
    if (existingFlashcards != null) {
      setState(() {
        flashcards =
            List<Map<String, dynamic>>.from(existingFlashcards['flashcards']);
        isLoading = false;
      });
    } else {
      await _generateFlashcards();
    }
  }

  Future<void> _generateFlashcards() async {
    final model = GenerativeModel(
      model: "gemini-1.5-pro",
      apiKey: 'AIzaSyDI7w8xqOS-8FrVzrHLTCdKTJilTd-pYh0',
    );

    try {
      final prompt = '''
Generate flashcards based on this title: ${widget.title} and content: ${widget.content}
Format the response as a JSON object with the following structure:
{
  "deck_name": "Flashcard Deck Title",
  "flashcards": [
    {
      "front": "Question or prompt",
      "back": "Answer or explanation",
      "tags": ["tag1", "tag2"]
    },
    // More flashcards...
  ]
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      log(response.text!);

      final regex = RegExp(r'json(.*?)', dotAll: true);
      final match = regex.firstMatch(response.text!);
      final jsonString = match?.group(1)?.trim() ?? '';
      final jsonResponse = jsonDecode(jsonString);

      setState(() {
        flashcards =
            List<Map<String, dynamic>>.from(jsonResponse['flashcards']);
        isLoading = false;
      });

      await _dbHelper.saveFlashcards(widget.title, flashcards);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating flashcards: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _nextCard() {
    setState(() {
      currentIndex = (currentIndex + 1) % flashcards.length;
      showingAnswer = false;
    });
  }

  void _previousCard() {
    setState(() {
      currentIndex = (currentIndex - 1 + flashcards.length) % flashcards.length;
      showingAnswer = false;
    });
  }

  void _toggleAnswer() {
    setState(() {
      showingAnswer = !showingAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (flashcards.isNotEmpty)
                    ? (currentIndex + 1) / flashcards.length
                    : 0.0,
                backgroundColor: const Color(0xFFA9ACBB),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF262D47)),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : flashcards.isEmpty
                        ? const Center(child: Text('No flashcards available'))
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flashcards: ${widget.title}',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF262D47)),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Tarjeta ${currentIndex + 1} de ${flashcards.length}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _toggleAnswer,
                                    child: Card(
                                      color: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: const BorderSide(
                                            color: Color(0xFFE8EFFF), width: 2),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                showingAnswer
                                                    ? flashcards[currentIndex]
                                                        ['back']
                                                    : flashcards[currentIndex]
                                                        ['front'],
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    color: Color(0xFF262D47)),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Icon(
                                              showingAnswer
                                                  ? MingCuteIcons
                                                      .mgc_book_2_line
                                                  : MingCuteIcons
                                                      .mgc_question_line,
                                              color: const Color(0xFF262D47),
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _previousCard,
                                      icon: const Icon(
                                          MingCuteIcons.mgc_left_line,
                                          color: Colors.white),
                                      label: const Text('Anterior',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF262D47),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _nextCard,
                                      icon: const Icon(
                                          MingCuteIcons.mgc_right_line,
                                          color: Colors.white),
                                      label: const Text('Siguiente',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF262D47),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(MingCuteIcons.mgc_left_fill,
                                      color: Color(0xFF262D47)),
                                  label: const Text('Regresar al apunte',
                                      style: TextStyle(
                                          color: Color(0xFF262D47),
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24.0),
                                      side: const BorderSide(
                                          color: Color(0xFF262D47), width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
