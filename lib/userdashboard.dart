import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'profile.dart';
import 'AddGrievance.dart';
import 'storage_service.dart';
import 'config.dart';
import 'logvisit.dart';
import 'refreshtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'complaint_status.dart';
import 'user_reminder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  String location = "Fetching location...";
  String userName = "";
  String user_id = "";
  String? pos;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData().then((_) => _getLocation());
  }


  Future<void> fetchDashboardData() async {
    String? token = await SecureStorage.getAccessToken();

    final url = Uri.parse("$baseURL/dashboard");

    http.Client client = http.Client();

    try {
      var response = await client.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",

        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Headers: ${response.headers}"); // Check if cookies are present

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        print("refresh function called");
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          print(token);
          response = await client.get(
            Uri.parse("$baseURL/dashboard"),
            headers: {"Authorization": "Bearer $token"},
          );
        }
        else{
          await SecureStorage.clearToken();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", false);
        }
      }
      print(response);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          userName = jsonResponse['name'];
          user_id = jsonResponse['user']['user_id'];
        });

        print("Response Body: ${response.body}");
      } else {
        print("Failed to fetch dashboard data");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      client.close();
    }
  }


  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => location = "Location services disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => location = "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => location = "Location permission permanently denied");
      return;
    }


    Position position = await Geolocator.getCurrentPosition();


    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      setState(() {
        location = placemarks[0].locality ?? "Unknown city"; // Display city name
      });
    }
    await logDashboardVisit(user_id, location);

  }



  void _navigateTo(BuildContext context, Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == 'profile_updated') {
      fetchDashboardData(); // 🟦 Refresh data if profile was updated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserReminder()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $userName!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Text(
              location, // ✅ Display user's city here
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            Text(
              'Post, Track, and Transform.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStatusCard('10', 'Complaints', Colors.blue)),
                SizedBox(width: 8),
                Expanded(child: _buildStatusCard('0', 'In Process', Colors.orange)),
                SizedBox(width: 8),
                Expanded(child: _buildStatusCard('0', 'Resolved', Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildComplaintCard('Amit Bhandana', 'Broken Footpath', 'assets/wire.jpg'),
                  _buildComplaintCard('Saksham Budhlani', 'Unattended Wires', 'assets/road.jpg'),
                  _buildComplaintCard('Yadav Kumar', 'Overcrowded Bus', 'assets/bus.jpg'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.blue,
        child: Container(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: Icon(Icons.home, color: Colors.white), onPressed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) => DashboardScreen()));
                    }),
                    IconButton(icon: Icon(Icons.dashboard, color: Colors.white), onPressed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) => Dashboard()));
                    }),
                  ],
                ),
              ),
              SizedBox(width: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: Icon(Icons.explore, color: Colors.white), onPressed: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (context) => DashboardScreen()));
                    }),
        IconButton(
          icon: Icon(Icons.person, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );

            if (result == 'profile_updated') {
              fetchDashboardData();
            }
          },
        ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => GrievanceScreen()));
          },
          backgroundColor: Colors.white,
          shape: CircleBorder(),
            elevation: 6,
          child: Icon(Icons.add, size: 32, color: Colors.blue)
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildStatusCard(String count, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(String user, String title, String imageUrl) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Text(
              user,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          // Positioned(
          //   bottom: 10,
          //   right: 10,
          //   child: Row(
          //     children: [
          //       Icon(Icons.thumb_up, color: Colors.white, size: 20),
          //       SizedBox(width: 5),
          //       Text(votes, style: TextStyle(color: Colors.white)),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
