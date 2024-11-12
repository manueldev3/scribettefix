import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribettefix/feature/calendar/presentation/pages/calendar_page.dart';
import 'package:scribettefix/feature/home/presentation/states/current_tab_state.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:scribettefix/feature/notebooks/presentation/pages/notebooks_page.dart';
import 'package:scribettefix/feature/recorder/presentation/pages/recorder_page.dart';
import 'package:scribettefix/feature/settings/presentation/pages/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static String path = '/home';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final pages = [
    const NotebooksPage(),
    const RecorderPage(),
    const CalendarPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabStateProvider);
    final currentTabNotifier = ref.read(currentTabStateProvider.notifier);
    return Scaffold(
      body: pages[currentTab],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        currentIndex: currentTab,
        onTap: currentTabNotifier.change,
        items: [
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: currentTab == 0
                ? const Icon(
                    MingCuteIcons.mgcBook6Fill,
                    color: Color(0xFF262D47),
                  )
                : const Icon(
                    MingCuteIcons.mgcBook6Line,
                    color: Color(0xFFA9ACBB),
                  ),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: currentTab == 1
                ? const Icon(
                    MingCuteIcons.mgcMicFill,
                    color: Color(0xFF262D47),
                  )
                : const Icon(
                    MingCuteIcons.mgcMicLine,
                    color: Color(0xFFA9ACBB),
                  ),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: currentTab == 2
                ? const Icon(
                    MingCuteIcons.mgcCalendarFill,
                    color: Color(0xFF262D47),
                  )
                : const Icon(
                    MingCuteIcons.mgcCalendarLine,
                    color: Color(0xFFA9ACBB),
                  ),
            label: '',
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: currentTab == 3
                ? const Icon(
                    MingCuteIcons.mgcSettings1Fill,
                    color: Color(0xFF262D47),
                  )
                : const Icon(
                    MingCuteIcons.mgcSettings1Line,
                    color: Color(0xFFA9ACBB),
                  ),
            label: '',
          ),
        ],
      ),
    );
  }
}
