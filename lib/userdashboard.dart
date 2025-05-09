import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'profile.dart';
import 'AddGrievance.dart';
import 'storage_service.dart';
import 'config.dart';
import 'logvisit.dart';
import 'refreshtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_complaint_status.dart';
import 'user_notifications.dart';
import 'getGrievanceById.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1B4F72),
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
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
  final TextEditingController _searchController = TextEditingController();
  int notificationCount = 0;
  int registered = 0;
  int inProcess = 0;
  int completed = 0;
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData().then((_) => _getLocation());
    fetchNotificationCount();
    fetchGrievanceStats();
    fetchComplaints();
  }

  Future<void> fetchNotificationCount() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await http.get(
        Uri.parse("$baseURL/countNotification"),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notificationCount = data['count'];
        });
      } else {
        print("Failed to fetch notifications, status code: ${response.statusCode}");
        await fetchGrievanceStats();
        await fetchComplaints();// Optional fallback
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  Future<void> fetchComplaints() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await http.get(
        Uri.parse("$baseURL/get_Public_Grievance"), // Replace with your API URL
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          complaints = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Failed to fetch grievances. Status code: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchGrievanceStats() async {
    String? token = await SecureStorage.getAccessToken();
    final url = Uri.parse("$baseURL/grievanceStats");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        setState(() {
          registered = stats['Registered'] ?? 0;
          inProcess = stats['InProcess'] ?? 0;
          completed = stats['Completed'] ?? 0;
        });
      }
    } catch (_) {}
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

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          response = await client.get(
            Uri.parse("$baseURL/dashboard"),
            headers: {"Authorization": "Bearer $token"},
          );
        } else {
          await SecureStorage.clearToken();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", false);
        }
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          userName = jsonResponse['name'];
          user_id = jsonResponse['user']['user_id'];
        });
      }
    } catch (_) {} finally {
      client.close();
    }
  }

  Future<void> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      setState(() => location = placemarks[0].locality ?? "Unknown city");
    }
    await logDashboardVisit(user_id, location);
  }

  Future<void> _fetchGrievanceById(String grievanceId) async {
    final token = await SecureStorage.getAccessToken();
    final url = Uri.parse('$baseURL/grievance_id?grievance_id=$grievanceId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final grievanceData = jsonDecode(response.body);
      Navigator.push(context, MaterialPageRoute(builder: (_) => GetGrievanceById(grievanceData: grievanceData)));
    } else {
      final error = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(error['message'] ?? 'Failed to fetch grievance.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: const Icon(Icons.menu, color: Colors.black87),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black87),

                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserReminder())),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 3,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),



        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600)),
            Text(location, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Grievance ID',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    final id = _searchController.text.trim();
                    if (id.isNotEmpty) _fetchGrievanceById(id);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusCard('$registered', 'Complaint', Colors.blue),
                const SizedBox(width: 10),
                _buildStatusCard('$inProcess', 'In Process', Colors.orange),
                const SizedBox(width: 10),
                _buildStatusCard('$completed', 'Resolved', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final userId = complaint["complainant_id"];
                  final description = complaint["description"];
                  final title = complaint["title"];
                  final imageUrl = complaint["media"]["image"];

                  return _buildComplaintCard(description, title, imageUrl);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GrievanceScreen())),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => Dashboard()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(String description, String title, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              "$baseURL/$imageUrl", // Replace with your domain
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/placeholder.jpg', fit: BoxFit.cover);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text(description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700])),
              ],
            ),
          )
        ],
      ),
    );
  }
}
