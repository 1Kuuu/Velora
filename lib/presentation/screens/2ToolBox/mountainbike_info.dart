import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/Weather/weather.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class MountainbikeInfo extends StatelessWidget {
  final Widget part;

  static List<Map<String, String>> parts = [];
  const MountainbikeInfo({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Center(child: part), // Using the new widget here
      floatingActionButton: TheFloatingActionButton(
        svgAsset: 'assets/svg/white-m.svg',
        onPressed: () => print("FAB Pressed"),
        backgroundColor: Colors.black,
        heroTag: 'openai_fab',
      ),
    );
  }
}

class MountainbikeHandlePart extends StatelessWidget {
  const MountainbikeHandlePart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Handle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Handle Bar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The MTB (mountain bike) handlebar is designed for off-road cycling and provides control, stability, and comfort on rough terrain.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MountainbikeWheelPart extends StatelessWidget {
  const MountainbikeWheelPart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Wheels.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Wheels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The MTB (mountain bike) wheel is designed to handle the challenges of off-road terrain, providing strength, durability, and traction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MountainbikeFramePart extends StatelessWidget {
  const MountainbikeFramePart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Frame.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Frame',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The "Frame" of a mountainbike refers to its frame and key structural components like the fork, seatpost, handlebars, bottom bracket, and wheel stays. These parts provide support, stability, and allow the bike to function.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MountainbikeSaddlePart extends StatelessWidget {
  const MountainbikeSaddlePart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Saddle.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Saddle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A good saddle is crucial for a comfortable and efficient riding experience, as it supports the riders weight and helps maintain proper riding posture.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MountainbikeCrankPart extends StatelessWidget {
  const MountainbikeCrankPart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Crank.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'Crank',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The crank is part of the bike drivetrain that connects the pedals to the bikes bottom bracket, allowing the rider to transfer power to the wheels.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class MountainbikeShifterPart extends StatelessWidget {
  const MountainbikeShifterPart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/mb-Shifter.png', // Replace with your actual image path
          height: 120,
        ),
        SizedBox(height: 10),
        Text(
          'shifter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'The shifter is a component on a road bike that allows the rider to change gears, controlling the bike speed and cadence. It is typically integrated into the handlebars and works in conjunction with the derailleur and chainrings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
