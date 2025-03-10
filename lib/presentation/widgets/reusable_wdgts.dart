import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:http/http.dart' as http;
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';

// ---------------------- BUTTON ----------------------
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String? iconPath;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 51,
      child: iconPath == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                text,
                style:
                    AppFonts.bold.copyWith(fontSize: 15, color: Colors.white),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Image.asset(iconPath!, height: 24),
              label: Text(
                text,
                style: AppFonts.semibold.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
    );
  }
}

// ---------------------- VELORA LOGO ----------------------
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 52.5,
      left: 17,
      child: Image.asset(
        'assets/images/logo.png',
        height: 35,
      ),
    );
  }
}

// ---------------------- TITLES ----------------------
class CustomTitleText extends StatelessWidget {
  final String text;

  const CustomTitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.bold.copyWith(
        fontSize: 48,
        color: AppColors.titletxt,
        letterSpacing: 4.8,
      ),
    );
  }
}

// ---------------------- SUBTITLES ----------------------
class CustomSubtitleText extends StatelessWidget {
  final String text;
  const CustomSubtitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.medium.copyWith(
        fontSize: 24,
        height: 1.2,
        letterSpacing: 5,
      ),
    );
  }
}

// ---------------------- -OR- ----------------------
class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.blacktxt)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or',
              style: AppFonts.semibold
                  .copyWith(color: AppColors.blacktxt, fontSize: 16)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.blacktxt)),
      ],
    );
  }
}

// ---------------------- TEXT FIELD || TEXT BOX ----------------------
class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
  });

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style:
              AppFonts.bold.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppFonts.bold.copyWith(fontSize: 16, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // Keep original radius
              borderSide: const BorderSide(
                  color: Colors.black, width: 1), // Keep original width
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: _toggleObscureText,
                  )
                : null, // Show icon only for password fields
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}

// ---------------------- DON'T || ALREADY ... HAVE AN ACCOUNT ----------------------
class AccountNavigationRow extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onPressed;

  const AccountNavigationRow({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(questionText),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.linkText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------- APP BAR ----------------------
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ---------------------- APP BAR ICON ----------------------
class AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AppBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.white,
      onPressed: onTap,
    );
  }
}

// ---------------------- ANIMATED BOTTOM NAV BAR ----------------------
class AnimatedBottomBarButton extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AnimatedBottomBarButton({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: body,
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        buttonBackgroundColor:
            isDarkMode ? const Color(0xFF4A3B7C) : AppColors.primary,
        height: 60,
        index: selectedIndex,
        onTap: onItemTapped,
        items: [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.build_outlined, color: Colors.white),
          Icon(Icons.newspaper_outlined, color: Colors.white),
          Icon(Icons.chat_bubble_outline, color: Colors.white),
          Icon(Icons.settings_outlined, color: Colors.white),
        ],
      ),
    );
  }
}

// ---------------------- FAB ----------------------
class TheFloatingActionButton extends StatelessWidget {
  final String? svgAsset;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final String? heroTag;

  const TheFloatingActionButton({
    super.key,
    this.svgAsset,
    this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4C9E), Color(0xFF4A3B7C)],
                  stops: [0.2, 0.8],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? const Color(0xFF4A3B7C).withOpacity(0.5)
                  : Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: heroTag ?? (svgAsset ?? icon.toString()),
          onPressed: onPressed,
          backgroundColor: isDarkMode ? Colors.transparent : AppColors.primary,
          elevation: isDarkMode ? 0 : 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: 40,
                  height: 40,
                )
              : Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

// ---------------------- DATE PICKER ----------------------
class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final Widget child;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.child,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  List<DateTime> holidayDates = [];

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    final year = DateTime.now().year;
    final url =
        Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/PH');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> holidays = jsonDecode(response.body);
        setState(() {
          holidayDates =
              holidays.map((h) => DateTime.parse(h['date'])).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }

  void _pickDate(BuildContext context) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.single,
                  initialSelectedDate: widget.initialDate,
                  selectionColor: AppColors.primary,
                  headerStyle: const DateRangePickerHeaderStyle(
                    textAlign: TextAlign.center,
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  selectionTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  selectionShape: DateRangePickerSelectionShape.rectangle,

                  // ✅ Correct way to add holiday dates
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    specialDates: holidayDates,
                  ),

                  monthCellStyle: DateRangePickerMonthCellStyle(
                    specialDatesDecoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    specialDatesTextStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                    widget.onDateSelected(args.value);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      widget.onDateSelected(DateTime.now());
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Today",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: widget.child,
    );
  }
}

// Utility class for chat-related functions
class ChatUtils {
  static Color generateRandomColor(String input) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink
    ];
    return colors[input.hashCode % colors.length];
  }

  static bool hasProfilePicture(String? url) {
    return url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true;
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

class ChatAppBar extends StatelessWidget {
  final String recipientName;
  final String recipientProfileUrl;
  final String recipientId;

  const ChatAppBar({
    super.key,
    required this.recipientName,
    required this.recipientProfileUrl,
    required this.recipientId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: recipientId),
        ),
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-25, 0),
            child: CircleAvatar(
              backgroundColor: ChatUtils.generateRandomColor(recipientName),
              backgroundImage: ChatUtils.hasProfilePicture(recipientProfileUrl)
                  ? NetworkImage(recipientProfileUrl)
                  : null,
              child: !ChatUtils.hasProfilePicture(recipientProfileUrl)
                  ? Text(
                      ChatUtils.getInitials(recipientName),
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    )
                  : null,
            ),
          ),
          Transform.translate(
            offset: const Offset(-18, 0),
            child: Flexible(
              child: Text(
                recipientName,
                style: AppFonts.bold.copyWith(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const MessageBubble({super.key, required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    String senderName = data["senderName"] ?? "Unknown";
    String messageText = data["text"] ?? "";
    DateTime? timestamp = (data["timestamp"] as Timestamp?)?.toDate();
    String status = data["status"] ?? "sent";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userId: data["senderId"]),
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: ChatUtils.generateRandomColor(senderName),
                backgroundImage:
                    ChatUtils.hasProfilePicture(data["senderProfileUrl"])
                        ? NetworkImage(data["senderProfileUrl"])
                        : null,
                child: !ChatUtils.hasProfilePicture(data["senderProfileUrl"])
                    ? Text(
                        ChatUtils.getInitials(senderName),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      )
                    : null,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    senderName,
                    style: AppFonts.medium
                        .copyWith(fontSize: 12, color: Colors.grey[700]),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: AppFonts.regular.copyWith(
                          fontSize: 14,
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(timestamp!),
                            style: AppFonts.light.copyWith(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _buildStatusIndicator(status),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    switch (status) {
      case 'sent':
        return Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.grey);
      case 'seen':
        return Icon(Icons.done_all, size: 14, color: Colors.white);
      default:
        return const SizedBox();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class DateHeader extends StatelessWidget {
  final String dateKey;

  const DateHeader({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(dateKey),
            style:
                AppFonts.medium.copyWith(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.parse(dateKey);
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    } else {
      return "${_getMonthName(date.month)} ${date.day}, ${date.year}";
    }
  }

  String _getMonthName(int month) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppFonts.regular.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: AppFonts.light.copyWith(fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: AppColors.hintText, width: 1),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: onSendPressed,
          ),
        ],
      ),
    );
  }
}

// USED IN TOOLBOX
class BikeSelectionDialog extends StatelessWidget {
  final Function(String) onBikeSelected;

  const BikeSelectionDialog({super.key, required this.onBikeSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          width: 535,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBikeOption(context, 'ROAD BIKE',
                  'assets/images/roadbike.png', 'ROADBIKE'),
              _buildBikeOption(context, 'MOUNTAIN BIKE',
                  'assets/images/mountainbike.png', 'MOUNTAINBIKE'),
              _buildBikeOption(
                  context, 'FIXIE', 'assets/images/fixie.png', 'FIXIE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBikeOption(
      BuildContext context, String title, String imagePath, String bikeType) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onBikeSelected(bikeType);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 20, top: 10),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this to reusable_wdgts.dart
class BikePartsGrid extends StatelessWidget {
  final List<String> titles;
  final List<String> images;
  final Function(int) onPartTap;

  const BikePartsGrid({
    super.key,
    required this.titles,
    required this.images,
    required this.onPartTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemCount: titles.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => onPartTap(index),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(images[index], height: 60),
                SizedBox(height: 6),
                Text(
                  titles[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Add this to reusable_wdgts.dart
class BikeUtils {
  static List<String> getTitles(String selectedBike) {
    if (selectedBike.toLowerCase() == 'roadbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'SHIFTER'];
    } else if (selectedBike.toLowerCase() == 'fixie') {
      return ['HANDLE', 'WHEELS', 'FRAME', 'SADDLE', 'CRANK', 'BRAKE'];
    }
    return [
      'HANDLE',
      'WHEELS',
      'FRAME',
      'SADDLE',
      'CRANK',
      'SHIFTER'
    ]; // Default
  }

  static List<String> getImages(String selectedBike) {
    String prefix = '';
    if (selectedBike.toLowerCase() == 'roadbike') {
      prefix = 'rd';
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      prefix = 'mb';
    } else if (selectedBike.toLowerCase() == 'fixie') {
      prefix = 'fx';
    } else {
      prefix = 'rd'; // Default
    }

    List<String> parts = getTitles(selectedBike);
    List<String> images = parts.map((part) {
      if (part == 'BRAKE') {
        return 'assets/images/$prefix-Break.png';
      }
      return 'assets/images/$prefix-${part.capitalize()}.png';
    }).toList();

    return images;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
