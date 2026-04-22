import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/pet.dart';
import 'package:mad2_etr_silva/screens/mood/add_mood_log.dart';
import 'package:mad2_etr_silva/screens/mood/view_pet_logs.dart';

class MoodLogsScreen extends StatefulWidget {
  @override
  _MoodLogsScreenState createState() => _MoodLogsScreenState();
}

class _MoodLogsScreenState extends State<MoodLogsScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late Box petsBox;

   @override
  void initState() {
    super.initState();
    petsBox = Hive.box('petsBox');
    _syncPetsFromFirebase();
  }

  Future<void> _syncPetsFromFirebase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      Pet pet = Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      await petsBox.put(doc.id, pet);
    }
  }

    @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: petsBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return Center(child: Text('No pets found.'));
            }

            List keys = box.keys.toList();
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                Pet pet = box.get(keys[index]);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side: Icon + Pet Info
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppColors.lightGreen,
                                child: Icon(Icons.pets, color: AppColors.darkGreen),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  SizedBox(height: 4),
                                  Text("Species: ${pet.species}", style: TextStyle(fontSize: 12)),
                                  Text("Breed: ${pet.breed}", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right side: Buttons
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lightGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddMoodLogScreen(
                                        petId: pet.id,
                                        petName: pet.name,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("Add Log", style: TextStyle(color: AppColors.darkGreen, fontSize: 12)),
                              ),
                            ),
                            SizedBox(height: 6),
                            SizedBox(
                              width: 110,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.lightGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewPetLogsScreen(
                                        petId: pet.id,
                                        petName: pet.name,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("View Logs", style: TextStyle(color: AppColors.darkGreen, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
