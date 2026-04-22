import 'package:flutter/material.dart';
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/screens/mood/mood_logs.dart';
import 'package:mad2_etr_silva/screens/pet/pet_profile.dart';
import 'package:mad2_etr_silva/screens/user/user_profile.dart';
import 'package:mad2_etr_silva/screens/map/vet_map.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    PetProfileScreen(),
    VetMapScreen(),
    MoodLogsScreen(),
    UserProfileScreen(), // This is the updated user profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo2.png',
              fit: BoxFit.cover,
              height: 75,
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.darkGreen,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.lightGreen,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pet Profiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Nearby Vets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mood Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
