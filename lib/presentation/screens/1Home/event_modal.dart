import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

// Event model to store event data
class Event {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAllDay;
  final String repeatStatus;
  final Color color;
  final String id;
  final String userId;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.repeatStatus,
    required this.color,
    required this.id,
    required this.userId,
  });

  // Convert TimeOfDay to Map
  Map<String, int> _timeOfDayToMap(TimeOfDay time) {
    return {
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  // Convert Map to TimeOfDay
  static TimeOfDay _timeOfDayFromMap(Map<String, dynamic> map) {
    return TimeOfDay(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': _timeOfDayToMap(startTime),
      'endTime': _timeOfDayToMap(endTime),
      'isAllDay': isAllDay,
      'repeatStatus': repeatStatus,
      'color': color.value,
      'userId': userId,
    };
  }

  // Create Event from Firestore document
  static Event fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime:
          _timeOfDayFromMap(Map<String, dynamic>.from(data['startTime'])),
      endTime: _timeOfDayFromMap(Map<String, dynamic>.from(data['endTime'])),
      isAllDay: data['isAllDay'] ?? false,
      repeatStatus: data['repeatStatus'] ?? 'None',
      color: Color(data['color'] as int),
      userId: data['userId'] ?? '',
    );
  }

  // Create a copy of the event with updated fields
  Event copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? repeatStatus,
    Color? color,
    String? userId,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      repeatStatus: repeatStatus ?? this.repeatStatus,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}

// Helper function to format TimeOfDay
String formatTimeOfDay(TimeOfDay timeOfDay) {
  final now = DateTime.now();
  final dateTime =
      DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  final format = DateFormat.jm(); // This will give you the time in AM/PM format
  return format.format(dateTime);
}

// Event Modal functionality
class EventModalHelper {
  // Show new event modal
  static void showNewEventModal(
    BuildContext context, {
    Event? existingEvent,
    DateTime? selectedDate,
    required Function(Event) onEventCreated,
    required Function(Event) onEventUpdated,
  }) {
    final titleController =
        TextEditingController(text: existingEvent?.title ?? "");
    final descriptionController =
        TextEditingController(text: existingEvent?.description ?? "");
    TimeOfDay startTime =
        existingEvent?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime =
        existingEvent?.endTime ?? const TimeOfDay(hour: 10, minute: 0);
    DateTime? eventDate = selectedDate ?? existingEvent?.date ?? DateTime.now();
    bool isAllDay = existingEvent?.isAllDay ?? false;
    String repeatStatus = existingEvent?.repeatStatus ?? "None";
    Color selectedColor = existingEvent?.color ?? Colors.blue;
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.red)),
                        ),
                        Text(
                          existingEvent != null ? "Edit Task" : "New Task",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (existingEvent != null) {
                              // Update existing event
                              final updatedEvent = existingEvent.copyWith(
                                title: titleController.text.isEmpty
                                    ? "Untitled Task"
                                    : titleController.text,
                                description: descriptionController.text,
                                date: eventDate ?? DateTime.now(),
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor,
                              );

                              onEventUpdated(updatedEvent);
                            } else {
                              // Create a new event
                              final newEvent = Event(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                title: titleController.text.isEmpty
                                    ? "Untitled Task"
                                    : titleController.text,
                                description: descriptionController.text,
                                date: eventDate ?? DateTime.now(),
                                startTime: startTime,
                                endTime: endTime,
                                isAllDay: isAllDay,
                                repeatStatus: repeatStatus,
                                color: selectedColor,
                                userId: FirebaseAuth.instance.currentUser!.uid,
                              );

                              onEventCreated(newEvent);
                            }

                            Navigator.pop(context);
                          },
                          child: const Text("Save",
                              style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),

                    // Event Title Input
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter event title",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Event Details Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          // Time Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimeButton(
                                startTime.format(context),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (pickedTime != null) {
                                    setModalState(() {
                                      startTime = pickedTime;
                                    });
                                  }
                                },
                                isDarkMode: isDarkMode,
                              ),
                              Icon(
                                Icons.arrow_right_alt,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              _buildTimeButton(
                                endTime.format(context),
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (pickedTime != null) {
                                    setModalState(() {
                                      endTime = pickedTime;
                                    });
                                  }
                                },
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),

                          // Date Picker
                          CustomDatePicker(
                            initialDate: eventDate!,
                            onDateSelected: (DateTime pickedDate) {
                              setModalState(() {
                                eventDate = pickedDate;
                              });
                            },
                            child: _buildTile(
                              icon: Icons.calendar_today,
                              text:
                                  DateFormat('EEEE, MMMM d').format(eventDate!),
                              isDarkMode: isDarkMode,
                            ),
                          ),

                          // All Day Toggle
                          _buildSwitchTile(
                            icon: Icons.access_time,
                            text: "All day",
                            value: isAllDay,
                            onChanged: (val) {
                              setModalState(() {
                                isAllDay = val;
                              });
                            },
                            isDarkMode: isDarkMode,
                          ),

                          // Repeat Dropdown
                          _buildDropdownTile(
                            icon: Icons.refresh,
                            selectedValue: repeatStatus,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setModalState(() {
                                  repeatStatus = newValue;
                                });
                              }
                            },
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Description Field
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Description",
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white38 : Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Color Selection
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Task Color",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildColorOption(
                                Colors.red,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.red;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.blue,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.blue;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.green,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.green;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.orange,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.orange;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.purple,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.purple;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.teal,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.teal;
                                  });
                                },
                              ),
                              _buildColorOption(
                                Colors.brown,
                                selectedColor,
                                () {
                                  setModalState(() {
                                    selectedColor = Colors.brown;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widgets for the modal
  static Widget _buildTimeButton(String time,
      {required VoidCallback onTap, required bool isDarkMode}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? const Color(0xFF3D3D3D) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 5),
          Text(
            time,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTile({
    required IconData icon,
    required String text,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_drop_down,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
    );
  }

  static Widget _buildSwitchTile({
    required IconData icon,
    required String text,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return SwitchListTile(
      title: Text(
        text,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
    );
  }

  static Widget _buildDropdownTile({
    required IconData icon,
    required String selectedValue,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : Colors.black54,
      ),
      title: DropdownButton(
        value: selectedValue,
        items: ["None", "Daily", "Weekly", "Monthly"].map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
      ),
    );
  }

  static Widget _buildColorOption(
      Color color, Color selectedColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: selectedColor == color
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
