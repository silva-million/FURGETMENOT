import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mad2_etr_silva/components/colors.dart';

class AddPetScreen extends StatefulWidget {
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _vaccinationController = TextEditingController();
  final TextEditingController _healthNotesController = TextEditingController();
  String _selectedSpecies = 'Dog';
  String _selectedGender = 'Male';
  String? _selectedBreed;
  List<String> _breeds = [];
  List<String> _filteredBreeds = [];

  final String _dogApiUrl = 'https://api.thedogapi.com/v1/breeds';
  final String _catApiUrl = 'https://api.thecatapi.com/v1/breeds';

  final String _dogApiKey =
      "live_m8KIkcxuTkC3kVDCWN4aDTn31kTG5yAlPeo1nIF69F9wLBpcdjGvawSD8So31vjc";
  final String _catApiKey =
      "live_i8atiYn7nDECJPE16B3oqnywiSWnpCk8uaEfs57aYJ5SZIQ9BIKs9UuDbCHvsux7";

  // Fetch dog breeds from The Dog API
  Future<void> fetchDogBreeds() async {
    final response = await http.get(
      Uri.parse(_dogApiUrl),
      headers: {"x-api-key": _dogApiKey},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _breeds = data.map((breed) => breed['name'] as String).toList();
        _filteredBreeds = _breeds;
      });
    } else {
      throw Exception('Failed to load dog breeds');
    }
  }

  // Fetch cat breeds from The Cat API
  Future<void> fetchCatBreeds() async {
    final response = await http.get(
      Uri.parse(_catApiUrl),
      headers: {"x-api-key": _catApiKey},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _breeds = data.map((breed) => breed['name'] as String).toList();
        _filteredBreeds = _breeds;
      });
    } else {
      throw Exception('Failed to load cat breeds');
    }
  }

  // Function to handle adding the pet to Firestore
  Future<void> addPet() async {
    try {
      String name = _nameController.text.trim();
      String age = _ageController.text.trim();
      String species = _selectedSpecies;
      String gender = _selectedGender;
      String breed = _selectedBreed ?? '';

      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('pets').add({
        'name': name,
        'breed': breed,
        'species': species,
        'gender': gender,
        'age': age,
        'birthday': _birthdayController.text.trim(),
        'healthNotes':
            _healthNotesController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        'vaccinationHistory':
            _vaccinationController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        'ownerId': userId,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding pet")));
    }
  }

  @override
  void initState() {
    super.initState();
    if (_selectedSpecies == 'Dog') {
      fetchDogBreeds();
    }
  }

  // Function to show a searchable dialog for breeds
  void _showBreedSearchDialog(BuildContext context) {
    _searchController.clear();
    setState(() {
      _filteredBreeds = _breeds;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                'Search Breed',
                style: TextStyle(color: AppColors.darkGreen, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      labelStyle: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.lightGreen,
                          width: 3,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.lightGreen,
                          width: 2,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _filteredBreeds =
                            _breeds
                                .where(
                                  (breed) => breed.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                )
                                .toList();
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    child:
                        _filteredBreeds.isEmpty
                            ? Center(
                              child: Text(
                                'No breeds found',
                                style: TextStyle(color: Colors.black),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredBreeds.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      0xFFF5E6E6,
                                    ), // Light pink background
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      _filteredBreeds[index],
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedBreed = _filteredBreeds[index];
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.darkGreen),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Pet",
          style: TextStyle(fontSize: 15, color: AppColors.darkGreen),
        ),
        backgroundColor: AppColors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Pet Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Pet Name',
                  labelStyle: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Age Field
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Species Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGreen, width: 3),
                ),
                child: DropdownButton<String>(
                  value: _selectedSpecies,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSpecies = newValue!;
                      _selectedBreed = null;
                      _breeds.clear();
                      _filteredBreeds.clear();
                      if (_selectedSpecies == 'Dog') {
                        fetchDogBreeds();
                      } else {
                        fetchCatBreeds();
                      }
                    });
                  },
                  items:
                      <String>['Dog', 'Cat'].map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  isExpanded: true,
                  underline: SizedBox(),
                ),
              ),
              SizedBox(height: 10),
              // Breed Dropdown with Search
              GestureDetector(
                onTap: () => _showBreedSearchDialog(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightGreen, width: 3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBreed ?? 'Select Breed',
                        style: TextStyle(
                          color:
                              _selectedBreed == null
                                  ? Colors.grey
                                  : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Gender Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGreen, width: 3),
                ),
                child: DropdownButton<String>(
                  value: _selectedGender,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                  items:
                      <String>['Male', 'Female'].map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  isExpanded: true,
                  underline: SizedBox(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: 'Birthday (e.g. 2021-06-15)',
                  labelStyle: TextStyle(color: AppColors.darkGreen),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _vaccinationController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Vaccination History (1 per line)',
                  labelStyle: TextStyle(color: AppColors.darkGreen),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _healthNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Health Notes (1 per line)',
                  labelStyle: TextStyle(color: AppColors.darkGreen),
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.lightGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Add Pet Button
              ElevatedButton(
                onPressed: addPet,
                child: Text(
                  "Add Pet",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGreen,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
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
