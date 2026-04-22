import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart'; // add Hive imports
import 'package:hive/hive.dart';
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/pet.dart';
import 'package:mad2_etr_silva/screens/pet/add_pet.dart';
import 'package:mad2_etr_silva/screens/pet/pet_details.dart'; // import your Pet model

class PetProfileScreen extends StatefulWidget {
  @override
  _PetProfileScreenState createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late Box petsBox;

  @override
  void initState() {
    super.initState();
    petsBox = Hive.box('petsBox');
    _syncPetsFromFirebase();
  }

  Future<void> _syncPetsFromFirebase() async {
    await petsBox.clear();
    final snapshot =
        await FirebaseFirestore.instance
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
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPetScreen()),
                );
              },
              icon: Icon(Icons.add, color: AppColors.darkGreen),
              label: Text(
                'Add Pet',
                style: TextStyle(color: AppColors.darkGreen),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: petsBox.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return Center(child: Text('No pets found.'));
                }
                List keys = box.keys.toList();
                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    Pet pet = box.get(keys[index]);
                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PetDetailScreen(petData: pet),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              pet.species == 'Dog'
                                  ? FontAwesomeIcons.dog
                                  : FontAwesomeIcons.cat,
                              size: 50,
                              color: AppColors.darkGreen,
                            ),
                            SizedBox(height: 10),
                            Text(
                              pet.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            Text('Age: ${pet.age}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
