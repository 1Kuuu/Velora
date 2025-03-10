import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/2ToolBox/fixie_info.dart';
import 'package:velora/presentation/screens/2ToolBox/mountainbike_info.dart';
import 'package:velora/presentation/screens/2ToolBox/roadbike_info.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';

class ToolboxPageContent extends StatelessWidget {
  const ToolboxPageContent({super.key});

  Future<String?> getSelectedBike() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      return doc.data()?['bike_type'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Toolbox",
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: getSelectedBike(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return BikeScreens(bikeType: snapshot.data!);
          }
          return Center(child: Text("No Bike Selected"));
        },
      ),
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () => print("FAB Pressed"),
        backgroundColor: isDarkMode ? const Color(0xFF4A3B7C) : Colors.black,
        heroTag: 'openai_fab',
      ),
    );
  }
}

class BikeScreens extends StatefulWidget {
  final String bikeType;

  const BikeScreens({Key? key, required this.bikeType}) : super(key: key);

  @override
  _BikeScreenState createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreens> {
  late String selectedBike;
  double opacity = 1.0;

  @override
  void initState() {
    super.initState();
    selectedBike = widget.bikeType.toLowerCase();
  }

  void changeBike(String newBike) async {
    setState(() {
      opacity = 0.0; // Start Fade Out
    });

    await Future.delayed(
        Duration(milliseconds: 300)); // Wait for fade-out animation

    setState(() {
      selectedBike = newBike.toLowerCase();
      opacity = 1.0; // Start Fade In
    });
  }

  // Get parts based on bike type
  List<String> getTitles() {
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

  // Get images based on bike type
  List<String> getImages() {
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

    String capitalizeFirst(String text) {
      if (text.isEmpty) return text;
      return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
    }

    List<String> parts = getTitles();
    List<String> images = parts.map((part) {
      if (part == 'BRAKE') {
        return 'assets/images/$prefix-Break.png';
      }
      return 'assets/images/$prefix-${capitalizeFirst(part)}.png';
    }).toList();

    return images;
  }

  void navigateToPartInfo(BuildContext context, int index) {
    String partName = BikeUtils.getTitles(selectedBike)[index].toLowerCase();

    if (selectedBike.toLowerCase() == 'roadbike') {
      switch (partName) {
        case 'handle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoadbikeInfo(part: RoadbikeHandlePart())),
          );
          break;
        case 'wheels':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoadbikeInfo(part: RoadbikeWheelPart())),
          );
          break;
        case 'frame':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoadbikeInfo(part: RoadbikeFramePart())),
          );
          break;
        case 'saddle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoadbikeInfo(part: RoadbikeSaddlePart())),
          );
          break;
        case 'crank':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RoadbikeInfo(part: RoadbikeCrankPart())),
          );
          break;
        case 'shifter':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RoadbikeInfo(part: RoadbikeShifterPart())),
          );
          break;
        default:
          print("No matching part found");
      }
    } else if (selectedBike.toLowerCase() == 'mountainbike') {
      switch (partName) {
        case 'handle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeHandlePart())),
          );
          break;
        case 'wheels':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeWheelPart())),
          );
          break;
        case 'frame':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeFramePart())),
          );
          break;
        case 'saddle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeSaddlePart())),
          );
          break;
        case 'crank':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeCrankPart())),
          );
          break;
        case 'shifter':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MountainbikeInfo(part: MountainbikeShifterPart())),
          );
          break;
        default:
          print("No matching part found");
      }
    } else if (selectedBike.toLowerCase() == 'fixie') {
      switch (partName) {
        case 'handle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieHandlePart())),
          );
          break;
        case 'wheels':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieWheelPart())),
          );
          break;
        case 'frame':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieFramePart())),
          );
          break;
        case 'saddle':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieSaddlePart())),
          );
          break;
        case 'crank':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieCrankPart())),
          );
          break;
        case 'brake':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FixiebikeInfo(part: FixieBreakPart())),
          );
          break;
        default:
          print("No matching part found");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    List<String> titles = BikeUtils.getTitles(selectedBike);
    List<String> images = BikeUtils.getImages(selectedBike);

    return Container(
      padding: EdgeInsets.all(16),
      color: isDarkMode ? const Color(0xFF121212) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: isDarkMode ? 0 : 4,
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    selectedBike,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Image.asset(
                      'assets/images/${selectedBike.toLowerCase()}.png',
                      width: 250,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.grey,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(width: 3),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor:
                            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: 'Most Recent',
                        underline: SizedBox(),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                        dropdownColor:
                            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        items: ['Most Recent', 'Previous', 'Old']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return BikeSelectionDialog(
                          onBikeSelected: (newBike) {
                            FirebaseFirestore.instance
                                .collection('user_preferences')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update({'bike_type': newBike});
                            changeBike(newBike.toUpperCase());
                            (context as Element).markNeedsBuild();
                          },
                        );
                      },
                    );
                  },
                  child: Text(
                    'Change',
                    style: AppFonts.bold.copyWith(
                      fontSize: 13,
                      color: isDarkMode
                          ? const Color(0xFF4A3B7C)
                          : AppColors.lightGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: GridView.builder(
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
                  onTap: () => navigateToPartInfo(context, index),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(
                        color:
                            isDarkMode ? const Color(0xFF4A3B7C) : Colors.brown,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          images[index],
                          height: 60,
                        ),
                        SizedBox(height: 6),
                        Text(
                          titles[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
