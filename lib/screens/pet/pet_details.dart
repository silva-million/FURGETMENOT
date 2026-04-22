import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/pet.dart';
import 'package:mad2_etr_silva/screens/pet/edit_pet.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet petData;

  PetDetailScreen({required this.petData});

  @override
  Widget build(BuildContext context) {
    final String species = petData.species;
    final IconData speciesIcon =
        species == 'Dog' ? FontAwesomeIcons.dog : FontAwesomeIcons.cat;

    return Scaffold(
      backgroundColor: Color(0xFFFDF8F0),
      appBar: AppBar(
        title: Text(petData.name),
        backgroundColor: AppColors.lightGreen,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.lightGreen,
                        child: Icon(
                          speciesIcon,
                          size: 40,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        petData.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(thickness: 1.2, color: Colors.grey[300]),
                      SizedBox(height: 10),
                      infoRow("Age", petData.age.toString()),
                      infoRow("Species", petData.species),
                      infoRow("Breed", petData.breed),
                      infoRow("Gender", petData.gender),
                      infoRow(
                        "Birthday",
                        petData.birthday != null
                            ? petData.birthday!.toLocal().toString().split(
                              ' ',
                            )[0]
                            : "N/A",
                      ),

                      SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vaccination History:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...petData.vaccinationHistory
                              .split(',')
                              .map((item) => Text("• ${item.trim()}")),
                          SizedBox(height: 10),
                          Text(
                            "Health Notes:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...petData.healthNotes
                              .split(',')
                              .map((item) => Text("• ${item.trim()}")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPetScreen(petData: petData),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, color: AppColors.darkGreen),
                  label: Text(
                    "Edit",
                    style: TextStyle(color: AppColors.darkGreen),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightGreen,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    "Delete",
                    style: TextStyle(color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text("$title:", style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Delete Pet"),
            content: Text("Are you sure you want to delete this pet?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: AppColors.darkGreen),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final petsBox = Hive.box('petsBox');
                  await petsBox.delete(petData.id);
                  await FirebaseFirestore.instance
                      .collection('pets')
                      .doc(petData.id)
                      .delete();
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Pet deleted')));
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
