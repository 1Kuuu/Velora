import 'package:flutter/material.dart';

// ---------------------- USED IN setting_screen.dart -------------------------------- //
// Section Title for lists
Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8, top: 10, bottom: 5),
    child: Text(title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
  );
}

// List Tile for settings options
Widget buildListTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  String? trailingText,
}) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(vertical: 4), // Adds spacing between tiles
    child: Material(
      color: Colors.white, // Background color
      borderRadius: BorderRadius.circular(12), // Rounded corners
      child: InkWell(
        onTap: onTap, // Makes the entire tile clickable
        borderRadius:
            BorderRadius.circular(12), // Ink effect inside rounded tile
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Light shadow effect
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailingText != null
                  ? Text(trailingText,
                      style: const TextStyle(fontSize: 14, color: Colors.grey))
                  : const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    ),
  );
}

// Dark Mode Toggle
Widget buildToggleTile({
  required String title,
  required bool value,
  required ValueChanged<bool> onChanged,
  required IconData icon,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.black),
    title: Text(title, style: const TextStyle(fontSize: 16)),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
    ),
  );
}
// ---------------------- END HERE -------------------------------- //
