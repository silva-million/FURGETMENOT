import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/pet.dart';

class EditPetScreen extends StatefulWidget {
  final Pet petData;

  EditPetScreen({required this.petData});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
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

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.petData.name;
    _ageController.text = widget.petData.age;
    _selectedSpecies = widget.petData.species;
    _selectedGender = widget.petData.gender;
    _selectedBreed = widget.petData.breed;
    _birthdayController.text =
        widget.petData.birthday != null
            ? widget.petData.birthday!.toIso8601String().split('T')[0]
            : '';
    _vaccinationController.text = widget.petData.vaccinationHistory.replaceAll(
      ',',
      '\n',
    );
    _healthNotesController.text = widget.petData.healthNotes.replaceAll(
      ',',
      '\n',
    );

    // Fetch breeds according to species
    if (_selectedSpecies == 'Dog') {
      fetchDogBreeds();
    } else {
      fetchCatBreeds();
    }
  }

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
    }
  }

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
    }
  }

  Future<void> updatePet() async {
    final petsBox = Hive.box('petsBox');

    try {
      // Update locally in Hive
      final updatedPet = Pet(
        id: widget.petData.id,
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        species: _selectedSpecies,
        breed: _selectedBreed ?? '',
        gender: _selectedGender,
        birthday:
            _birthdayController.text.trim().isNotEmpty
                ? DateTime.parse(_birthdayController.text.trim())
                : null,
        vaccinationHistory: _vaccinationController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .join(','),
        healthNotes: _healthNotesController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .join(','),
        ownerId: widget.petData.ownerId,
      );

      await petsBox.put(widget.petData.id, updatedPet);

      // Then sync to Firestore
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petData.id)
          .update(updatedPet.toMap());

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Pet updated successfully")));
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update pet")));
    }
  }

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
                      suffixIcon: Icon(Icons.search),
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
                            ? Center(child: Text('No breeds found'))
                            : ListView.builder(
                              itemCount: _filteredBreeds.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_filteredBreeds[index]),
                                  onTap: () {
                                    setState(() {
                                      _selectedBreed = _filteredBreeds[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
        title: Text("Edit Pet"),
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

              // Age Field (Free-form)
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age (e.g. 2 years, 6 months)',
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

              // Breed Search
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

              // Birthday Field
              TextField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: 'Birthday (e.g. 2021-06-15)',
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

              // Vaccination History Field
              TextField(
                controller: _vaccinationController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Vaccination History (1 per line)',
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

              // Health Notes Field
              TextField(
                controller: _healthNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Health Notes (1 per line)',
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

              // Update Button
              ElevatedButton(
                onPressed: updatePet,
                child: Text(
                  "Update Pet",
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
