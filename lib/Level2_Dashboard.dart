import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'getGrievanceById.dart';
import 'profile.dart';
import 'storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'refreshtoken.dart';
import 'Level2_NewAssignedGrievance.dart';
import 'Level2_AcceptedGrievance.dart';
import 'L2officer_notifications.dart';
import 'logvisit.dart';
import 'disposed_grievances.dart';
import 'returned_grievance.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grievance System',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Level2Dashboard(),
    );
  }
}

class Level2Dashboard extends StatefulWidget {
  const Level2Dashboard({super.key});

  @override
  State<Level2Dashboard> createState() => _Level2DashboardState();
}

class _Level2DashboardState extends State<Level2Dashboard> {
  int _currentIndex = 0;
  String userName = "";
  String user_id = "";

  final List<Widget> _pages = [
    HomePage(),
    DummyPage("History"),
    ProfileScreen(),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          // BottomNavigationBarItem(icon: Icon(Icons.feed), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile",

          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String user_id = "";
  String userId = "";
  String location = "Fetching location...";
  int notificationCount = 0;


  @override
  void initState() {
    super.initState();
    fetchDashboardData().then((_) => _getLocation());
    fetchLatestGrievances();
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

  Future<List<Grievance>> fetchLatestGrievances() async {
    String? token = await SecureStorage.getAccessToken();
    final response = await http.get(Uri.parse('$baseURL/displayL_G'),
    headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Grievance.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load grievances');
    }
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
        // Optional fallback
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  final TextEditingController _searchController = TextEditingController();
  Future<void> _fetchGrievanceById(String grievanceId) async {
    var token = await SecureStorage.getAccessToken();
    var url = Uri.parse('$baseURL/get_grievance_idl2?grievance_id=$grievanceId');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    // if(response.statusCode == 401){
    //   bool refreshed = await refreshToken();
    //   if (refreshed) {
    //     token = await SecureStorage.getAccessToken();
    //     response = await http.get(url, headers: {
    //       'Authorization': 'Bearer $token',
    //       'Content-Type': 'application/json'
    //     });
    //         }
    // }

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
          color: Colors.black,
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelReminderPage()));
                },
                color: Colors.black,
              ),
              if (notificationCount > 0)
                Positioned(
                  right: -1,  // Adjust this value to move horizontally
                  top: -1,    // Adjust this value to move vertically
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Text(
            'Hello, $userName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(location, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),

          FutureBuilder<List<Grievance>>(
            future: fetchLatestGrievances(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No grievances found');
              }

              final grievances = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Grievance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.9),
                      children: grievances.map((g) {
                        return _TrendingCard(
                          title: g.title,
                          grievanceId: g.grievanceId,
                          description: g.description,
                          date: DateFormat('MMM dd, yyyy').format(g.createdAt),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // All Services
          const Text(
            'All Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _ServiceCard(
                icon: Icons.report,
                label: "New Grievance",
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Level2_NewGrievancePage()),
                    ),
              ),
              _ServiceCard(
                icon: Icons.fact_check_outlined,
                label: "Accepted",
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Level2_AcceptedGrievancePage()),
                    ),
              ),
              _ServiceCard(
                icon: Icons.cancel_outlined,
                label: "Returned",
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReturnedGrievancePage()),
                    ),
              ),
              _ServiceCard(
                icon: Icons.verified,
                label: "Disposed",
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DisposedGrievancesPage()),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

  class Grievance {
  final String grievanceId;
  final String title;
  final String description;
  final DateTime createdAt;

  Grievance({
    required this.grievanceId,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      grievanceId: json['grievance_id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}



// Trending Card
class _TrendingCard extends StatelessWidget {
  final String title;
  final String description;
  final String grievanceId;
  final String date;
  const _TrendingCard({required this.title, required this.description, required this.grievanceId, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$title ($grievanceId)",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: TextStyle(
              fontSize: 12,
              height: 1.0,
            ),),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.share, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Service Card
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blue.shade800, size: 30),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder Page
class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title Page',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}