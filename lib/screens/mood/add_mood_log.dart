import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad2_etr_silva/components/colors.dart';

class AddMoodLogScreen extends StatefulWidget {
  final String? petId;
  final String? petName;

  AddMoodLogScreen({this.petId, this.petName});

  @override
  _AddMoodLogScreenState createState() => _AddMoodLogScreenState();
}

class _AddMoodLogScreenState extends State<AddMoodLogScreen> {
  String? _selectedPetId;
  String? _selectedPetName;
  String? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  List<DocumentSnapshot> _userPets = [];
  final List<String> _moodOptions = ['Happy', 'Sad', 'Playful', 'Anxious', 'Sick'];

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    _selectedPetName = widget.petName;
    fetchUserPets();
  }

  Future<void> fetchUserPets() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .get();

    setState(() {
      _userPets = snapshot.docs;
    });
  }

  Future<void> saveMoodLog() async {
    if (_selectedPetId == null || _selectedMood == null || _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('mood_logs').add({
      'petId': _selectedPetId,
      'petName': _selectedPetName,
      'ownerId': userId,
      'mood': _selectedMood,
      'notes': _notesController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mood log saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Mood Log'),
        backgroundColor: AppColors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Select Pet Dropdown
              if (_selectedPetId == null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightGreen, width: 3),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPetId,
                    hint: Text('Select Pet'),
                    isExpanded: true,
                    underline: SizedBox(),
                    items: _userPets.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                        onTap: () {
                          _selectedPetName = doc['name'];
                        },
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPetId = value;
                      });
                    },
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Pet: $_selectedPetName", style: TextStyle(fontSize: 16)),
                ),
              SizedBox(height: 15),

              // Mood Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGreen, width: 3),
                ),
                child: DropdownButton<String>(
                  value: _selectedMood,
                  hint: Text('Select Mood'),
                  isExpanded: true,
                  underline: SizedBox(),
                  items: _moodOptions.map((mood) {
                    return DropdownMenuItem<String>(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMood = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 15),

              // Notes Field
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Notes or Journal',
                  labelStyle: TextStyle(color: AppColors.darkGreen, fontSize: 16),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.lightGreen, width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.lightGreen, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: saveMoodLog,
                child: Text(
                  "Save Mood Log",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGreen,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
