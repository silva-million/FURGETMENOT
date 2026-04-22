import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mad2_etr_silva/components/colors.dart';

class ViewPetLogsScreen extends StatefulWidget {
  final String petId;
  final String petName;

  ViewPetLogsScreen({required this.petId, required this.petName});

  @override
  _ViewPetLogsScreenState createState() => _ViewPetLogsScreenState();
}

class _ViewPetLogsScreenState extends State<ViewPetLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final petId = widget.petId;
    final petName = widget.petName;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        title: Text("Logs of $petName"),
        backgroundColor: AppColors.lightGreen,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mood_logs')
            .where('petId', isEqualTo: petId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading logs.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No logs found for $petName'));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index];
              final createdAt = data['createdAt'].toDate();
              final formattedDate =
                  "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood text only (no delete button)
                      Text(
                        data['mood'],
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Notes
                      Text(
                        data['notes'],
                        style: TextStyle(fontSize: 15),
                      ),

                      SizedBox(height: 10),

                      // Date
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "Logged on: $formattedDate",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
