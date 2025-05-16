import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'disposed_grievances.dart';
import 'refreshtoken.dart';
import 'storage_service.dart';
import 'user_grievance_detail.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.indigo.shade50,
      ),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  List<dynamic> grievances = [];
  bool isLoading = true;

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        grievances = data['grievance'];
        isLoading = false;
      });
    } else {
      print("Failed to fetch grievances: ${response.statusCode}");
    }
  }

  List<dynamic> getFilteredGrievances() {
    if (_selectedIndex == 0) {
      return grievances;
    } else if (_selectedIndex == 1) {
      // In Process -> isdisposed == false
      return grievances.where((g) => g["isdisposed"] == false).toList();
    } else if (_selectedIndex == 2) {
      // Disposed -> isdisposed == true
      return grievances.where((g) => g["isdisposed"] == true).toList();
    }
    return [];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if(index == 2){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DisposedGrievancesPage()),
      );
    }
  }

  Widget buildComplaintCard(Map<String, dynamic> complaint) {
    final List<dynamic> images = complaint['media']?['images'] ?? [];
    final imageUrl = images.isNotEmpty ? "$baseURL/${images[0]}" : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GrievanceDetailPage(complaint: complaint),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade200.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.white,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.indigo),
                    ),
                  );
                },
              )
                  : Container(
                height: 180,
                color: Colors.indigo.shade50,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.indigo),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint["title"] ?? "No Title",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint["description"] ?? "No Description",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGrievances = grievances;
    final inProcessGrievances =
    grievances.where((g) => g["isdisposed"] == false).toList();
    final disposedGrievances =
    grievances.where((g) => g["isdisposed"] == true).toList();

    final filteredGrievances = getFilteredGrievances();

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : filteredGrievances.isEmpty
          ? const Center(
        child: Text(
          "No grievances found.",
          style: TextStyle(color: Colors.indigo),
        ),
      )
          : ListView.builder(
        itemCount: filteredGrievances.length,
        itemBuilder: (context, index) =>
            buildComplaintCard(filteredGrievances[index]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sync),
            label: 'In Process',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.done),
            label: 'Disposed',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo.shade700,
        unselectedItemColor: Colors.indigo.shade300,
        onTap: _onItemTapped,
        backgroundColor: Colors.indigo.shade50,
      ),
    );
  }
}
