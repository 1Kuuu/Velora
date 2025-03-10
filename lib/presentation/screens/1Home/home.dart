import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/toolbox.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/4Chat/chat_list.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'event_modal.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomePageContent(),
    const ToolboxPageContent(),
    const NewsFeedPageContent(),
    const ChatListPage(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomBarButton(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      selectedIndex: _selectedIndex,
      onItemTapped: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<Event>>? _eventsStream;
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _updateEventsStream();
  }

  void _updateEventsStream() {
    if (_auth.currentUser == null) return;

    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _eventsStream = _firestore
        .collection('events')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      _events = snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      return _events;
    });
  }

  List<DateTime> getWeekDays(DateTime date) {
    int weekday = date.weekday;
    DateTime sunday = date.subtract(Duration(days: weekday % 7));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateEventsStream();
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      _showToast('Event deleted successfully');
    } catch (e) {
      _showToast('Error deleting event: $e', isError: true);
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Event event) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "${event.title}"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(event.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _editEvent(Event event) {
    EventModalHelper.showNewEventModal(
      context,
      existingEvent: event,
      selectedDate: _selectedDate,
      onEventCreated: (newEvent) async {
        try {
          await _firestore.collection('events').add(newEvent.toFirestore());
        } catch (e) {
          _showToast('Error creating event: $e', isError: true);
        }
      },
      onEventUpdated: (updatedEvent) async {
        try {
          await _firestore
              .collection('events')
              .doc(updatedEvent.id)
              .update(updatedEvent.toFirestore());
        } catch (e) {
          _showToast('Error updating event: $e', isError: true);
        }
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Colors.red : Colors.green,
          ),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Home",
        actions: [
          AppBarIcon(
            icon: Icons.cloud_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeatherScreen()),
              );
            },
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/add.svg',
        onPressed: () {
          if (_auth.currentUser == null) {
            _showToast('Please log in to create events');
            return;
          }

          EventModalHelper.showNewEventModal(
            context,
            selectedDate: _selectedDate,
            onEventCreated: (newEvent) async {
              try {
                await _firestore
                    .collection('events')
                    .add(newEvent.toFirestore());
              } catch (e) {
                _showToast('Error creating event: $e', isError: true);
              }
            },
            onEventUpdated: (updatedEvent) async {
              try {
                await _firestore
                    .collection('events')
                    .doc(updatedEvent.id)
                    .update(updatedEvent.toFirestore());
              } catch (e) {
                _showToast('Error updating event: $e', isError: true);
              }
            },
          );
        },
        backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
        heroTag: "fab_add_event",
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          return Column(
            children: [
              // Weekly Progress Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Weekly Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _progressItem("Activities", events.length.toString(),
                              isDarkMode),
                          _progressItem("Time", "0h 0m", isDarkMode),
                          _progressItem("Distance", "0.00km", isDarkMode),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar Header with Menu Icon & Clickable Date
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                child: Row(
                  children: [
                    CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      },
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    CustomDatePicker(
                      initialDate: _selectedDate,
                      onDateSelected: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      },
                      child: Text(
                        DateFormat.yMMMM().format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Weekday Labels + Dates (Clickable)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 60,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
                            .day,
                        (index) {
                          DateTime currentDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            index + 1,
                          );
                          bool isSelected =
                              _selectedDate.day == currentDate.day &&
                                  _selectedDate.month == currentDate.month &&
                                  _selectedDate.year == currentDate.year;

                          bool hasEvents = events.any((event) =>
                              event.date.day == currentDate.day &&
                              event.date.month == currentDate.month &&
                              event.date.year == currentDate.year);

                          return GestureDetector(
                            onTap: () => _onDateSelected(currentDate),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat.E().format(currentDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDarkMode
                                                  ? Colors.white24
                                                  : Colors.black12)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? (isDarkMode
                                                    ? Colors.white38
                                                    : Colors.black26)
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            currentDate.day.toString(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? (isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87)
                                                  : isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (hasEvents)
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87)
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Display Events for the Selected Date
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note,
                                size: 48,
                                color:
                                    isDarkMode ? Colors.white38 : Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              "No Plans for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}",
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap + to add a new Plan",
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          Event event = events[index];
                          return Dismissible(
                            key: Key(event.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) => _deleteEvent(event.id),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: event.color
                                  .withOpacity(isDarkMode ? 0.8 : 1.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _editEvent(event),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _showDeleteConfirmation(
                                                      context, event),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${DateFormat('EEEE, MMMM d').format(event.date)} | ${formatTimeOfDay(event.startTime)} - ${formatTimeOfDay(event.endTime)}",
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event.description,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _progressItem(String title, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        Icon(
          Icons.arrow_drop_up,
          color: isDarkMode ? Colors.white54 : Colors.black54,
        ),
        Text(
          "0",
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
