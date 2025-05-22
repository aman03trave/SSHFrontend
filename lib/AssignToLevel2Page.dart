import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssh/customsnackbar.dart';
import 'dart:convert';
import 'storage_service.dart';
import 'config.dart';
import 'refreshtoken.dart';
import 'Level1_dashboard.dart';

void main() {
  runApp(const MaterialApp(home: AssignToLevel2Page()));
}

class GrievanceItem {
  final String grievanceId;
  final String title;
  final String location;
  final String complainantName;
  final String schoolName;
  final String blockName;
  final String duration;

  const GrievanceItem({
    required this.grievanceId,
    required this.title,
    required this.location,
    required this.complainantName,
    required this.schoolName,
    required this.blockName,
    required this.duration,
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    return GrievanceItem(
      grievanceId: json['grievance_id'].toString(),
      title: json['title'] ?? 'Untitled',
      location: "${json['block_name'] ?? ''}, ${json['school_name'] ?? ''}",
      complainantName: json['complainant_name'] ?? 'Unknown',
      schoolName: json['school_name'] ?? 'Unknown',
      blockName: json['block_name'] ?? 'Unknown',
      duration: json['duration'] ?? 'N/A',
    );
  }
}

class AssignToLevel2Page extends StatefulWidget {
  const AssignToLevel2Page({super.key});

  @override
  State<AssignToLevel2Page> createState() => _AssignToLevel2PageState();
}

class _AssignToLevel2PageState extends State<AssignToLevel2Page> {
  List<GrievanceItem> grievances = [];
  // List<Map<String, dynamic>> officerDataList = [];
  // Map<String, String> officerNameToId = {};
  bool isLoading = true;

  final List<Color> cardColors = [
    Colors.white,
    const Color(0xFFE6F0FD),
    const Color(0xFFE0F7FA),
    const Color(0xFFFFF8E1),
  ];

  @override
  void initState() {
    super.initState();
    loadData();

  }

  Future<void> loadData() async {
    try {
      String? token = await SecureStorage.getAccessToken();

      var response = await http.get(
        Uri.parse('$baseURL/getGrievancesByDistrict'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          response = await http.get(
            Uri.parse('$baseURL/getGrievancesByDistrict'),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List grievanceData = jsonDecode(response.body);
        setState(() {
          grievances = grievanceData.map((item) => GrievanceItem.fromJson(item)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }


  Future<void> assignGrievance(String grievanceId, String officerId) async {
    String? token = await SecureStorage.getAccessToken();

    Future<http.Response> sendAssignment() => http.post(
      Uri.parse('$baseURL/assignGrievance'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        'grievance_id': grievanceId,
        'assigned_to': officerId,
      }),
    );

    var response = await sendAssignment();

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await sendAssignment();
      }
    }

    if (response.statusCode == 200) {
      showCustomSnackBar(context, "Grievance Assigned");
      setState(() {}

      );
      loadData();
    } else {
      throw Exception('Failed to assign grievance');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => GrievanceDashboard()),
              (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          title: const Text("Assign to Level 2"),

          leading: Navigator.canPop(context)
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GrievanceDashboard())),
          )
              : null,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: grievances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return GrievanceAssignCard(
                      item: grievances[index],
                      // officerMap: officerNameToId,
                      onAssign: assignGrievance,
                      backgroundColor: cardColors[index % cardColors.length],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GrievanceAssignCard extends StatefulWidget {
  final GrievanceItem item;
  final Function(String, String) onAssign;
  final Color backgroundColor;

  const GrievanceAssignCard({
    super.key,
    required this.item,
    required this.onAssign,
    required this.backgroundColor,
  });

  @override
  State<GrievanceAssignCard> createState() => _GrievanceAssignCardState();
}

class _GrievanceAssignCardState extends State<GrievanceAssignCard> {
  String? selectedOfficer;
  Map<String, String> officerMap = {};
  bool officerLoading = false;

  Future<void> fetchOfficersForGrievance(String grievanceId) async {
    print(grievanceId);
    try {
      setState(() {
        officerLoading = true;
      });

      String? token = await SecureStorage.getAccessToken();
      var response = await http.get(
        Uri.parse('$baseURL/getBlockOfficersWithGrievanceCount?grievance_id=$grievanceId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          response = await http.get(
            Uri.parse('$baseURL/getBlockOfficersWithGrievanceCount?grievance_id=$grievanceId'),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List officerData = jsonDecode(response.body);
        setState(() {
          officerMap = {
            for (var o in officerData)
              "${o['officer_name']} (Grievances: ${o['grievance_count']})": o['officer_id'].toString()
          };
          officerLoading = false;
        });
      } else {
        throw Exception("Failed to fetch officers");
      }
    } catch (e) {
      print("Error fetching officers: $e");
      setState(() {
        officerLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Automatically fetch officers once this widget is initialized
    fetchOfficersForGrievance(widget.item.grievanceId);
  }
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("🏫 School: ${widget.item.schoolName}", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text("📍 Block: ${widget.item.blockName}", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          officerLoading
              ? const Center(child: CircularProgressIndicator())
              :DropdownButtonFormField<String>(
            value: selectedOfficer,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelText: "Assign to Block Officer",
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: officerMap.keys.map((officerName) {
              return DropdownMenuItem<String>(
                value: officerName,
                child: Text(officerName, style: const TextStyle(fontSize: 14)),
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
                onPressed: () async {
                  try {
                    await widget.onAssign(
                      widget.item.grievanceId,
                      officerMap[selectedOfficer]!,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Assignment failed: $e")),
                    );
                  }
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