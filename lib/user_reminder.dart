import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    fetchReminders();
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

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
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
          grievanceList = data
              .where((item) =>
          !(item['notification_type'] == 'Reminder Eligibility' &&
              item['can_send_reminder'] == false)) // ✅ SKIP invalid reminder eligibility
              .map<Map<String, dynamic>>((item) {
            final title = item['title'] ?? '';
            final grievanceId = item['grievance_id'] ?? '';
            final notificationType = item['notification_type'] ?? '';
            final canSend = item['can_send_reminder'] ?? false;

            final messages = <String>[];

            if (notificationType == 'Complaint Registered') {
              messages.add('You have lodged a grievance titled "$title".');
            } else if (notificationType == 'Reminder Eligibility') {
              messages.add('You are now eligible to send a reminder for "$title".');
            } else if (notificationType == 'Reminder Sent') {
              messages.add('You have already sent a reminder for "$title".');
            } else {
              messages.add('Update on "$title": $notificationType');
            }

            return {
              'title': title,
              'grievance_id': grievanceId,
              'messages': messages,
              'showReminderSection': canSend,
              'reminderStatus': canSend ? 'Reminder can be sent' : 'Reminder not eligible',
              'canSendReminder': canSend,
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


  void sendReminder(String grievanceId) async {
    final token = await SecureStorage.getAccessToken();
    Map<String, dynamic> requestBody = {

      "grievanceId": grievanceId,
    };
    try {
      final response = await http.post(
        Uri.parse('$baseURL/addReminder'),
        headers: {'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },

        body: jsonEncode(requestBody)
      );

      if (response.statusCode == 200) {
        setState(() {
          final grievance = grievanceList.firstWhere((g) => g['grievance_id'] == grievanceId);
          grievance['messages'].add('You have already sent a reminder for "${grievance['title']}".');
          grievance['reminderStatus'] = 'Reminder already sent';
          grievance['canSendReminder'] = false;
        });

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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reminder has been sent successfully.',
                  style: GoogleFonts.poppins(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        print('Failed to send reminder: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reminder')),
        );
      }
    } catch (e) {
      print('Error sending reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending reminder')),
      );
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Reminders"),
        backgroundColor: Colors.blue,
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
          : grievanceList.isEmpty
          ? const Center(child: Text("No pending reminders available."))
          : ListView.builder(
        itemCount: grievanceList.length,
        itemBuilder: (context, index) {
          final grievance = grievanceList[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grievance Title
                  Text(
                    grievance['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Show each message under the grievance
                  ...grievance['messages'].map<Widget>((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('• $msg', style: const TextStyle(color: Colors.black87)),
                  )),
                  // Show reminder section if eligible
                  if (grievance['showReminderSection']) ...[
                    const SizedBox(height: 10),
                    Text(grievance['reminderStatus'],
                        style: const TextStyle(color: Colors.blueAccent)),
                    if (grievance['canSendReminder'])
                      ElevatedButton(
                        onPressed: () => sendReminder(grievance['grievance_id']),
                        child: const Text('Send Reminder'),
                      ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }


}
