import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'pet.g.dart';

@HiveType(typeId: 0)
class Pet extends HiveObject {
  @HiveField(0)
  String id; // Firestore doc id

  @HiveField(1)
  String name;

  @HiveField(2)
  String species;

  @HiveField(3)
  String breed;

  @HiveField(4)
  String gender;

  @HiveField(5)
  String age;

  @HiveField(6)
  DateTime? birthday;

  @HiveField(7)
  String healthNotes;

  @HiveField(8)
  String vaccinationHistory;

  @HiveField(9)
  String ownerId;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.age,
    this.birthday,
    required this.healthNotes,
    required this.vaccinationHistory,
    required this.ownerId,
  });

  factory Pet.fromMap(Map<String, dynamic> map, String id) {
  DateTime? birthday;

  if (map['birthday'] != null) {
    if (map['birthday'] is Timestamp) {
      birthday = (map['birthday'] as Timestamp).toDate();
    } else if (map['birthday'] is String) {
      birthday = DateTime.tryParse(map['birthday']);
    }
  }

  String healthNotes = '';
  if (map['healthNotes'] != null) {
    if (map['healthNotes'] is List) {
      healthNotes = (map['healthNotes'] as List<dynamic>).join(', ');
    } else if (map['healthNotes'] is String) {
      healthNotes = map['healthNotes'];
    }
  }

  String vaccinationHistory = '';
  if (map['vaccinationHistory'] != null) {
    if (map['vaccinationHistory'] is List) {
      vaccinationHistory = (map['vaccinationHistory'] as List<dynamic>).join(', ');
    } else if (map['vaccinationHistory'] is String) {
      vaccinationHistory = map['vaccinationHistory'];
    }
  }

  return Pet(
    id: id,
    name: map['name'] ?? '',
    species: map['species'] ?? '',
    breed: map['breed'] ?? '',
    gender: map['gender'] ?? '',
    age: map['age'] ?? '',
    birthday: birthday,
    healthNotes: healthNotes,
    vaccinationHistory: vaccinationHistory,
    ownerId: map['ownerId'] ?? '',
  );
}



  Map<String, dynamic> toMap() => {
    'name': name,
    'species': species,
    'breed': breed,
    'gender': gender,
    'age': age,
    'birthday': birthday,
    'healthNotes': healthNotes,
    'vaccinationHistory': vaccinationHistory,
    'ownerId': ownerId,
  };
}
