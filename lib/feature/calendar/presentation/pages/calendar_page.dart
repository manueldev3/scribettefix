import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/core/helpers/database_helper.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  Map<DateTime, List<String>> eventsDate = {};

  void loadEvents() async {
    DatabaseHelper dbHelper = DatabaseHelper();

    // try {
    //   Map<DateTime, List<String>> loadedEvents = {};
    //   Map<DateTime, List<String>> rawEvents = await dbHelper.getEventsByDate();

    //   rawEvents.forEach((date, eventList) {
    //     DateTime dateTime = DateTime(date.year, date.month, date.day);
    //     loadedEvents[dateTime] = eventList;
    //   });

    //   debugPrint(loadedEvents.toString());

    //   setState(() {
    //     eventsDate = loadedEvents;
    //   });
    // } catch (e, s) {
    //   debugPrint('$e: $s');
    // }
  }

  List<String> _getEventsForDay(DateTime day) {
    return eventsDate[day] ?? [];
  }

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              context.lang!.calendarTitle,
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1e2337),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Beta',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1e2337),
      body: Column(
        children: [
          Expanded(
            child: Card(
              color: const Color(0xFF1e2337),
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    TableCalendar(
                      locale: Localizations.localeOf(context).toString(),
                      daysOfWeekHeight: 32,
                      eventLoader: _getEventsForDay,
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Color(0xFF878EA3),
                        ),
                        weekendStyle: TextStyle(color: Color(0xFF878EA3)),
                      ),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: focusedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(selectedDate, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          selectedDate = selectedDay;
                          focusedDate = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        selectedTextStyle:
                            const TextStyle(color: Color(0xFFBEC5DF)),
                        todayTextStyle:
                            const TextStyle(color: Color(0xFF878EA3)),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF434A64),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF434A64),
                            width: 2.0,
                          ),
                        ),
                        defaultTextStyle:
                            const TextStyle(color: Color(0xFF878EA3)),
                        weekendTextStyle:
                            const TextStyle(color: Color(0xFF878EA3)),
                        outsideTextStyle:
                            const TextStyle(color: Color(0xFF3E455E)),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.white),
                        titleTextStyle: TextStyle(color: Colors.white),
                      ),
                      calendarFormat: CalendarFormat.month,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            color: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Column(
                      children: _getEventsForDay(selectedDate).map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8EFFF),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF1e2337),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
