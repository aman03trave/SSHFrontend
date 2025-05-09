import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
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
      return grievances.where((g) =>
      g["action_code_id"] != 1 && g["action_code_id"] != 7).toList();
    } else if (_selectedIndex == 2) {
      return grievances.where((g) => g["action_code_id"] == 7).toList();
    }
    return [];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildComplaintCard(Map<String, dynamic> complaint) {
    final imagePath = complaint['media']?['image'];
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? "$baseURL/$imagePath"
        : '';

    return GestureDetector(
        onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GrievanceDetailPage(complaint: complaint),
        ),
      );
    },
      child: Card(

      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, size: 50)),
                );
              },
            ),
          ),
          ListTile(
            title: Text(complaint["title"] ?? "No Title"),
            subtitle: Text(complaint["description"] ?? "No Description"),
          ),
        ],
      ),
      )
    );
  }

  Widget buildBadge(int count) {
    return count > 0
        ? Positioned(
      right: -10,
      top: -10,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
    )
        : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final allGrievances = grievances;
    final inProcessGrievances = grievances
        .where((g) => g["action_code_id"] != 1 && g["action_code_id"] != 7)
        .toList();
    final disposedGrievances =
    grievances.where((g) => g["action_code_id"] == 7).toList();

    final filteredGrievances = getFilteredGrievances();

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: filteredGrievances.length,
        itemBuilder: (context, index) =>
            buildComplaintCard(filteredGrievances[index]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.list),
                buildBadge(allGrievances.length),
              ],
            ),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sync),
                buildBadge(inProcessGrievances.length),
              ],
            ),
            label: 'In Process',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.done),
                buildBadge(disposedGrievances.length),
              ],
            ),
            label: 'Disposed',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
