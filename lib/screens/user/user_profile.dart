import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/screens/user/user_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _loading = true;
  late String _email;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    setState(() {
      _usernameController.text = doc.data()?['username'] ?? '';
      _email = user!.email ?? '';
      _loading = false;
    });
  }

  Future<void> _saveUsername() async {
    if (user == null) return;

    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'username': newUsername});
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Username updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update username')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.lightGreen,
              child: Icon(Icons.person, size: 60, color: AppColors.darkGreen),
            ),
            SizedBox(height: 30),

            // Username field with edit/save button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    enabled: _isEditing,
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: AppColors.darkGreen),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.lightGreen,
                          width: 2,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.orange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: AppColors.darkGreen,
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      _saveUsername();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Email display (read-only)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              child: Text(
                _email,
                style: TextStyle(fontSize: 16, color: AppColors.darkGreen),
              ),
            ),

            Spacer(),

            // Logout button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen without route name
                SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
  await Hive.box('petsBox').clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserLoginScreen()),
                );
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
