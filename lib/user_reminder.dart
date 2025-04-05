import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

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
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final List<Map<String, dynamic>> dummyGrievances = [
    {
      'id': 'GRV-0012',
      'title': 'Broken Classroom Bench',
      'description': 'Bench in room 102 is broken and unsafe.',
      'date': '2024-03-25',
      'canSendReminder': true,
    },
    {
      'id': 'GRV-0024',
      'title': 'No Water Supply',
      'description': 'No water in toilets for 3 days.',
      'date': '2024-03-20',
      'canSendReminder': true,
    },
    {
      'id': 'GRV-0055',
      'title': 'Playground Fence Damaged',
      'description': 'Children at risk due to broken fencing.',
      'date': '2024-03-10',
      'canSendReminder': false,
    },
  ];

  void _sendReminder(Map<String, dynamic> grievance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
              'Your reminder for grievance ${grievance['id']} has been sent successfully.',
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
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyGrievances.length,
        itemBuilder: (context, index) {
          final grievance = dummyGrievances[index];
          final canSend = grievance['canSendReminder'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                grievance['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                grievance['description'],
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
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
