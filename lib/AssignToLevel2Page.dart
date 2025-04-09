import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: AssignToLevel2Page()));
}

class AssignToLevel2Page extends StatelessWidget {
  const AssignToLevel2Page({super.key});

  final List<GrievanceItem> grievances = const [
    GrievanceItem(title: "Water Leakage", location: "Block A, Floor 1"),
    GrievanceItem(title: "Power Outage", location: "Building B, Room 203"),
    GrievanceItem(title: "Broken Chair", location: "Library, Reading Room"),
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> officers = [
      "Officer Rahul (Block A)",
      "Officer Priya (Block B)",
      "Officer Arjun (Block C)",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Assign to Level 2"),
        backgroundColor: const Color(0xFF3366CC),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.separated(
          itemCount: grievances.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return GrievanceAssignCard(
              item: grievances[index],
              officers: officers,
            );
          },
        ),
      ),
    );
  }
}


class GrievanceItem {
  final String title;
  final String location;

  const GrievanceItem({
    required this.title,
    required this.location,
  });
}

class GrievanceAssignCard extends StatefulWidget {
  final GrievanceItem item;
  final List<String> officers;

  const GrievanceAssignCard({
    super.key,
    required this.item,
    required this.officers,
  });

  @override
  State<GrievanceAssignCard> createState() => _GrievanceAssignCardState();
}

class _GrievanceAssignCardState extends State<GrievanceAssignCard> {
  String? selectedOfficer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.item.location,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedOfficer,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelText: "Assign to Block Officer",
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: widget.officers.map((officer) {
              return DropdownMenuItem<String>(
                value: officer,
                child: Text(officer, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedOfficer = value;
              });
            },
          ),
          if (selectedOfficer != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Perform assignment logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "${widget.item.title} assigned to $selectedOfficer."),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF3366CC),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Assign"),
              ),
            ),
        ],
      ),
    );
  }
}
