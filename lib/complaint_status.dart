import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:flutter/material.dart';
import 'refreshtoken.dart';
import 'storage_service.dart';

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
  List<dynamic> grievances = [];

  @override
  void initState() {
    super.initState();
    fetchGrievances();
  }

  Future<void> fetchGrievances() async {
    String? token = await SecureStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$baseURL/getgrievance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    print(response.body);

    if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Get new token and retry once
        token = await SecureStorage.getAccessToken();
        final retryResponse = await http.get(
          Uri.parse('$baseURL/getgrievance'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );

        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          setState(() {
            grievances = data['grievance'];
          });
          return;
        } else {
          print("Failed after refresh: ${retryResponse.statusCode}");
          return;
        }
      } else {
        print("Token refresh failed");
        return;
      }
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        grievances = data['grievance'];
      });
    } else {
      print("Failed to fetch grievances: ${response.statusCode}");
    }
  }


  void toggleExpanded(int index) {
    setState(() {
      expandedState[index] = !(expandedState[index] ?? false);
    });
  }

  Widget categoryCard(String title, int category) {
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildComplaintCard(Map<String, dynamic> complaint, int index) {
    final isExpanded = expandedState[index] ?? false;
    final imagePath = complaint['media']?['image'];
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? "$baseURL/$imagePath"
        : '';


    return GestureDetector(
      onTap: () => toggleExpanded(index),
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Container(
              height: 200,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.broken_image, size: 50)),
                  );
                },
              ),
            ),
            // Dark overlay
            Container(
              height: 200,
              color: Colors.black.withOpacity(0.4),
            ),
            // Title
            Positioned(
              bottom: 50,
              left: 15,
              child: Text(
                complaint["title"] ?? "No Title",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            // View Action button
            Positioned(
              bottom: 10,
              right: 10,
              child: ElevatedButton(
                onPressed: () => toggleExpanded(index),
                child: Text("View Action"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ),
            if (isExpanded)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description: ${complaint["description"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Action Status: ${complaint["action_code_id"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 5),
                        Text("Created At: ${complaint["created_at"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => toggleExpanded(index),
                            child: Text("Close", style: TextStyle(color: Colors.redAccent)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredGrievances = grievances
        .where((g) {
      if (selectedCategory == 1) return g["action_code_id"] == 2;
      if (selectedCategory == 2) return g["action_code_id"] == 3;
      return true;
    })
        .cast<Map<String, dynamic>>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              categoryCard("Complaints", 0),
              categoryCard("In Process", 1),
              categoryCard("Resolved", 2),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGrievances.length,
              itemBuilder: (context, index) =>
                  buildComplaintCard(filteredGrievances[index], index),
            ),
          ),
        ],
      ),
    );
  }
}
