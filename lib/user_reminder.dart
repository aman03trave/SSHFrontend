import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ssh/config.dart';
import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';
import 'userdashboard.dart';

void main() {
  runApp(const UserReminder());
}

class UserReminder extends StatelessWidget {
  const UserReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminders',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const ReminderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map<String, dynamic>> grievanceList = [];
  bool isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchReminders() async {
    try {
      String? token = await SecureStorage.getAccessToken();

      var response = await http.get(
        Uri.parse('$baseURL/getReminder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      print(response.body);

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          // 👇 Update this variable so that the next lines use the new response
          response = await http.get(
            Uri.parse('$baseURL/getReminder'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          grievanceList = data.map((item) {
            return {
              'title': item['title'],
              'description': item['description'],
              'grievance_id' : item['grievance_id'],
              'canSendReminder': item['can_send_reminder'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
    }
  }


  void _sendReminder(Map<String, dynamic> grievance) async {
    String? token = await SecureStorage.getAccessToken();

    try {
      var response = await http.post(
        Uri.parse('$baseURL/addReminder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'grievance_id': grievance['grievance_id'], // ✅ Ensure 'id' is included in grievance data
        }),
      );

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          // 👇 Update this variable so that the next lines use the new response
          response = await http.post(
            Uri.parse('$baseURL/getReminder'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
              'grievance_id': grievance['grievance_id'], // ✅ Ensure 'id' is included in grievance data
            }),
          );
        }
      }

      if (response.statusCode == 200) {
        // ✅ Update the local state to disable button after reminder is sent
        setState(() {
          grievance['canSendReminder'] = false;
        });

        // Show confirmation bottom sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Reminder Sent!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reminder has been sent successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      } else {
        print('Failed to send reminder: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder')),
        );
      }
    } catch (e) {
      print('Error sending reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reminder')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Reminders"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grievanceList.length,
        itemBuilder: (context, index) {
          final grievance = grievanceList[index];
          final canSend = grievance['canSendReminder'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              title: Text(
                grievance['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                grievance['description'],
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.black87),
              ),
              trailing: canSend
                  ? ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text("Send Reminder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _sendReminder(grievance),
              )
                  : const Text(
                "Already Sent",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}