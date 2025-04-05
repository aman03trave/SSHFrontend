import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedCategory = 0; // 0: All, 1: In Process, 2: Resolved
  Map<int, bool> expandedState = {};

  void toggleExpanded(int index) {
    setState(() {
      expandedState[index] = !(expandedState[index] ?? false);
    });
  }

  void showLogDialog(BuildContext context, String step) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Action Log"),
        content: Text("Details of $step"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                categoryCard("Complaints", 2, 0),
                categoryCard("In Process", 1, 1),
                categoryCard("Resolved", 1, 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                final isExpanded = expandedState[index] ?? false;
                return Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(complaint["title"]),
                        subtitle: Text(complaint["location"]),
                        trailing: IconButton(
                          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                          onPressed: () => toggleExpanded(index),
                        ),
                      ),
                      if (isExpanded)
                        Column(
                          children: complaint["steps"].map<Widget>((step) {
                            return ListTile(
                              leading: Icon(Icons.check_circle, color: Colors.green),
                              title: Text(step["title"]),
                              subtitle: Text(step["date"]),
                              trailing: IconButton(
                                icon: Icon(Icons.info_outline, color: Colors.blue),
                                onPressed: () => showLogDialog(context, step["title"]),
                              ),
                            );
                          }).toList(),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryCard(String title, int count, int category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedCategory == category ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> complaints = [
  {
    "title": "Broken Footpath",
    "location": "Opposite Xcel Campus",
    "steps": [
      {"title": "Registration", "date": "5th Oct"},
      {"title": "Acknowledgment", "date": "9th Oct"},
      {"title": "Investigation", "date": "11th Oct"},
      {"title": "Implementation", "date": "14th Oct"},
      {"title": "Closure", "date": "20th Oct"},
    ]
  },
  {
    "title": "Unattended Wires",
    "location": "Near Sector 4",
    "steps": [
      {"title": "Registration", "date": "9th Nov"},
      {"title": "Acknowledgment", "date": "11th Nov"},
      {"title": "Investigation", "date": "15th Nov"},
      {"title": "Implementation", "date": "18th Nov"},
      {"title": "Closure", "date": "22nd Nov"},
    ]
  }
];
