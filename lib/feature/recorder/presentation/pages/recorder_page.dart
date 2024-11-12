import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:scribettefix/feature/notebooks/presentation/state/notebook_state.dart';

class RecorderPage extends ConsumerStatefulWidget {
  const RecorderPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RecorderPageState();
}

class _RecorderPageState extends ConsumerState<RecorderPage> {
  int? selectedNotebookId;
  String selectedNoteType = 'Notes';
  List<String> notebookCategories = ['(Not Assignment)'];

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdatedSubscription;
  List<ProductDetails> _products = [];
  bool _isSubscribed = false;

  /// Recording
  bool isRecording = false;
  bool isPaused = false;
  int time = 0;
  late Timer _timer;
  late String filePath;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final maxRecordingTimePerDay = 60 * 60; // Una hora en segundos
  final int accumulatedTimeToday = 0;

  /// Instances
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// Recorder Controller
  final RecorderController _controller = RecorderController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _purchaseUpdatedSubscription?.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notebookState = ref.watch(notebooksStateProvider);
    final notebookNotifier = ref.read(notebooksStateProvider.notifier);

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
                  items: <String>[
                    'Notes', // Notes // itemStringNotes
                    'Meeting Minutes' // 'Meeting Minutes // itemStringMeeting
                  ].map<DropdownMenuItem<String>>((String value) {
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
                            onPressed: () {
                              // discardRecording();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isRecording) {
                                // stopRecording();
                              } else {
                                // startRecording();
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
                            onPressed: () {},
                            // pauseRecording,
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
}
