import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scribettefix/core/background_services.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/env.dart';
import 'package:scribettefix/feature/IA/domain/prompts/prompts.dart';
import 'package:scribettefix/feature/auth/presentation/states/auth_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';
import 'package:scribettefix/feature/notes/presentation/states/note_state.dart';
import 'package:scribettefix/feature/products/presentation/states/products_state.dart';
import 'package:scribettefix/feature/subscriptions/domain/subcriptions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecorderPage extends ConsumerStatefulWidget {
  const RecorderPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> {
  int? selectedNotebookId;
  String selectedNoteType = 'Notes';
  List<ProductDetails> _products = [];

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdatedSubscription;
  bool _isSubscribed = false;

  final firestore = FirebaseFirestore.instance;

  /// Recording
  bool isRecording = false;
  bool isPaused = false;
  DateTime dateStart = DateTime.now();
  int time = 0;
  Timer? _timer;
  late String filePath;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final maxRecordingTimePerDay = 60 * 60;
  int accumulatedTimeToday = 0;

  /// Instances
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final subscriptionRepository = SubcriptionsRepository();

  /// Recorder Controller
  final RecorderController _controller = RecorderController();

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _initSubscription();
  }

  @override
  void dispose() {
    _controller.dispose();
    _purchaseUpdatedSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notebookState = ref.watch(notebooksStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang!.recorderTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              notebookState.when(
                data: (data) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedNotebookId ?? data.first.id,
                    icon: const Icon(
                      MingCuteIcons.mgcDownFill,
                      color: Color(0xFF545A78),
                    ),
                    iconSize: 24,
                    elevation: 0,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF252D47),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    dropdownColor: const Color(0xFFE8EFFF),
                    underline: Container(),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedNotebookId = newValue!;
                      });
                    },
                    items: List<DropdownMenuItem<int>>.from(
                      data.map(
                        (notebook) {
                          return DropdownMenuItem<int>(
                            value: notebook.id,
                            child: Text(notebook.name),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                error: (error, stackTrace) {
                  log(
                    error.toString(),
                    error: error,
                    stackTrace: stackTrace,
                  );
                  return Container();
                },
                loading: () {
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedNoteType,
                  icon: const Icon(
                    MingCuteIcons.mgcDownFill,
                    color: Color(0xFF545A78),
                  ),
                  iconSize: 24,
                  elevation: 0,
                  style: const TextStyle(
                    color: Color(0xFF252D47),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  dropdownColor: const Color(0xFFE8EFFF),
                  underline: Container(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedNoteType = newValue!;
                    });
                  },
                  items: <String>['Notes', 'Meeting Minutes']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == "Notes"
                          ? context.lang!.itemStringNotes
                          : value == "Meeting Minutes"
                              ? context.lang!.itemStringMeeting
                              : value),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    AudioWaveforms(
                      enableGesture: true,
                      size: Size(
                        context.mediaQuery.size.width,
                        100,
                      ),
                      waveStyle: const WaveStyle(
                        waveColor: Color(0xFFA9ACBB),
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                      recorderController: _controller,
                    ),
                    const SizedBox(height: 32),
                    Visibility(
                      visible: isRecording,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 128, right: 128),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE8EFFF),
                              width: 2,
                            ),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF252D47),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: isRecording,
                          child: IconButton(
                            icon: const Icon(
                              MingCuteIcons.mgcDeleteLine,
                              color: Color(0xFFA9ACBB),
                              size: 32,
                            ),
                            onPressed: _discardRecording,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isRecording) {
                                _stopRecording();
                              } else {
                                _startRecording();
                              }
                              isRecording = !isRecording;
                              if (!isRecording) {
                                time = 0;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 5000),
                            padding: EdgeInsets.all(isRecording ? 12 : 6),
                            decoration: BoxDecoration(
                              color: isRecording
                                  ? const Color(0xFF252D47)
                                  : Colors.transparent,
                              border: Border.all(
                                  color: const Color(0xFF252D47), width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRecording
                                  ? MingCuteIcons.mgcCheckFill
                                  : Icons.circle,
                              color: isRecording
                                  ? Colors.white
                                  : const Color(0xFF252D47),
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Visibility(
                          visible: isRecording,
                          child: IconButton(
                            icon: Icon(
                                isPaused
                                    ? MingCuteIcons.mgcPlayFill
                                    : MingCuteIcons.mgcPauseFill,
                                color: Colors.grey,
                                size: 32),
                            onPressed: _pauseRecording,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  String formatDateMeeting(DateTime date) {
    return DateFormat('MMMM d, y HH:mm:ss a').format(date);
  }

  Future<void> _purchaseSubscription() async {
    if (_products.isEmpty) {
      debugPrint("No products available for purchase.");
      return;
    }

    ProductDetails productDetails = _products[0];
    PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Error initiating purchase: $e");
    }
  }

  Future<void> _verifyPurchase() async {
    final Stream<List<PurchaseDetails>> purchaseStream =
        _inAppPurchase.purchaseStream;
    final purchases = await purchaseStream.first;

    for (final purchaseDetails in purchases) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        setState(() {
          _isSubscribed = true;
        });
        return;
      }
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final result = await subscriptionRepository.checkSubscription();
    setState(() {
      _isSubscribed = result;
    });
  }

  Future<void> _initSubscription() async {
    final currentUser = ref.watch(authChangesProvider).value;
    final productsNotifier = ref.read(productsStateProvider.notifier);
    final bool available = await _inAppPurchase.isAvailable();
    if (available) {
      await productsNotifier.refresh();
      _purchaseUpdatedSubscription =
          _inAppPurchase.purchaseStream.listen((purchaseDetailsList) async {
        for (final purchaseDetails in purchaseDetailsList) {
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            String? email = currentUser?.email;
            DateTime purchaseDate = DateTime.now();
            DateTime expirationDate = purchaseDate.add(
              const Duration(days: 30),
            );

            await FirebaseFirestore.instance
                .collection('users')
                .doc(email)
                .collection('subscriptions')
                .doc('subscriptionInfo')
                .set({
              'isSubscribed': true,
              'purchaseDate': purchaseDate,
              'expirationDate': expirationDate,
            });
            setState(() {
              _isSubscribed = true;
            });
          } else {}
        }
      });
      _verifyPurchase();
    }
  }

  Future<void> _insertNoteFromSummary(String summary) async {
    final notebooksState = ref.watch(notebooksStateProvider);
    final noteNotifier = ref.read(noteStateProvider.notifier);

    List<String> summaryLines = summary.split('\n');
    String title = summaryLines.first;
    String content = summaryLines.skip(1).join('\n');

    DateTime now = DateTime.now();
    String timestamp = formatDateMeeting(now);

    final notebookId = selectedNotebookId ?? notebooksState.value?.first.id;

    if (notebookId != null) {
      await _dbHelper.insertFile(
        title: title.toLowerCase().contains('meeting minutes') ||
                title.toLowerCase().contains('acta de reunión')
            ? "$title - $timestamp"
            : title,
        content: content,
        date: timestamp,
        notebookId: notebookId,
      );

      final notebook = notebooksState.value!.firstWhere(
        (notebook) => notebook.id == selectedNotebookId,
        orElse: () => notebooksState.value!.first,
      );

      await noteNotifier.add(
        content: content,
        notebook: notebook.name,
        title: title,
        date: timestamp,
      );

      if (context.mounted) {
        final ctxt = context;
        final message = ctxt.lang!.noteSaved;
        _showSnackBar(message, title);
      }
    }
  }

  void _showSnackBar(String message, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //       builder: (context) => NotePage(
            //             articleTitle: title,
            //             refreshUi: () {},
            //           )),
            // );
          },
          child: Row(
            children: [
              const Icon(
                MingCuteIcons.mgcNotebook2Fill,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF252D47),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _requestPermisitions() async {
    await Permission.microphone.request();
  }

  Future<void> _startRecording() async {
    await enableBackgroundMode();

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int accumulatedTimeToday = prefs.getInt('accumulatedTime_$today') ?? 0;

    if (accumulatedTimeToday >= maxRecordingTimePerDay && !_isSubscribed) {
      _purchaseSubscription();
      _showSnackBar('Ya has alcanzado el límite de grabación para hoy.',
          'Límite diario alcanzado');
      return;
    }

    await _requestPermisitions();
    Directory directory = await getApplicationDocumentsDirectory();
    filePath = "${directory.path}/"
        "audio_${DateTime.now().millisecondsSinceEpoch}.mp3";

    await _controller.record(
      path: filePath,
      sampleRate: 48000,
      bitRate: 256000,
    );

    setState(() {
      isRecording = true;
      time = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(
        () {
          if (!isPaused) {
            time++;
          }
        },
      );
      if (accumulatedTimeToday + time >= maxRecordingTimePerDay &&
          !_isSubscribed) {
        _purchaseSubscription();

        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    await _controller.stop();

    setState(() {
      isRecording = false;
    });

    if ((_timer?.isActive ?? false) && !isPaused) {
      _timer?.cancel();
    }

    int recordedTime = time;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    accumulatedTimeToday = prefs.getInt('accumulatedTime_$today') ?? 0;

    accumulatedTimeToday += recordedTime;

    await prefs.setInt('accumulatedTime_$today', accumulatedTimeToday);

    final model = GenerativeModel(
      model: "gemini-1.5-pro",
      apiKey: Env.geminiApiKey,
    );

    final audioBytes = await File(filePath).readAsBytes();

    String prompt = "";

    if (selectedNoteType != 'Meeting Minutes') {
      if (context.mounted) {
        final ctxt = context;
        prompt = prompt1(ctxt, DateTime.now());
      }
    } else {
      if (context.mounted) {
        final ctxt = context;
        prompt = prompt2(
          ctxt,
          startTime: formatDate(dateStart),
          endTime: DateTime.now(),
          date: DateTime.now(),
        );
      }
    }

    final response = await model.generateContent(
      [
        Content.text(prompt),
        Content.data("audio/mp3", audioBytes),
      ],
    );

    String note = response.text!;

    RegExp regExp = RegExp(
      r'<Section of Dates>(.*?)<\/Section of Dates>',
      dotAll: true,
    );
    Match? match = regExp.firstMatch(response.text!);
    String dateToInsert;

    if (match != null) {
      String sectionContent = match.group(1)!;
      if (sectionContent.contains("{")) {
        dateToInsert = sectionContent;

        dateToInsert = dateToInsert.replaceAll("{", "");
        dateToInsert = dateToInsert.replaceAll("}", "");
        dateToInsert = dateToInsert.replaceAll("\"", "");

        var dateToInsertList = dateToInsert.split(',');
        var numberDate = dateToInsertList[0];
        var nameDate = dateToInsertList[1];

        try {
          // await _dbHelper.insertDate(nameDate, numberDate);

          _showSnackBarForDate(nameDate, numberDate);
        } catch (error, stackTrace) {
          debugPrint(error.toString());
          debugPrint(stackTrace.toString());
        }
      }

      note = note.replaceAll(match.group(0)!, "");
    }

    _insertNoteFromSummary(note);
    FlutterBackground.disableBackgroundExecution();
    ref.read(notebooksStateProvider.notifier).refresh();
  }

  void _showSnackBarForDate(String nameDate, String numberDate) {
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        final ctxt = context;
        ScaffoldMessenger.of(ctxt).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  MingCuteIcons.mgcCalendar2Fill,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ctxt.lang!.dateLabel}: $nameDate - $numberDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF252D47),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _discardRecording() async {
    if (isRecording) {
      await _controller.stop();
    }
    _timer?.cancel();

    setState(() {
      isRecording = false;
    });

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      if (context.mounted) {
        final ctxt = context;
        _showSnackBar(ctxt.lang!.noteDiscard, "");
      }
    }
  }

  Future<void> _pauseRecording() async {
    if (isRecording) {
      setState(() {
        if (isPaused) {
          _controller.record();

          isPaused = false;
        } else {
          _controller.pause();
          isPaused = true;
        }
      });
    }
  }
}
