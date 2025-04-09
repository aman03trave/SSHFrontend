import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ATRReportPage(),
  ));
}

class ATRReportPage extends StatelessWidget {
  final List<ATRReport> reports = [
    ATRReport(
      fileName: 'ATR for School Renovation',
      uploadedDate: 'April 5, 2025',
      officerName: 'Rahul Sharma',
      fileSize: '1.8MB',
      folder: 'Grievance 1024',
    ),
    ATRReport(
      fileName: 'ATR - Midday Meal Issue',
      uploadedDate: 'April 3, 2025',
      officerName: 'Priya Mehra',
      fileSize: '2.1MB',
      folder: 'Grievance 1029',
    ),
  ];

  void _acceptReport(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Acceptance"),
        content: Text("Are you sure you want to accept the ATR: $fileName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("ATR '$fileName' accepted.")),
              );
            },
            child: Text("Accept"),
          ),
        ],
      ),
    );
  }

  void _rejectReport(BuildContext context, String fileName) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Reject & Resend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Provide remarks for rejecting '$fileName':"),
            SizedBox(height: 10),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter remarks here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String remarks = remarksController.text.trim();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("ATR '$fileName' rejected. Remarks: $remarks")),
              );
            },
            child: Text("Send Back"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Submitted ATR Reports"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.fileName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip(Icons.calendar_today, report.uploadedDate),
                      _buildInfoChip(Icons.person, report.officerName),
                      _buildInfoChip(Icons.folder, report.folder),
                      _buildInfoChip(Icons.storage, report.fileSize),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.close, color: Colors.red),
                        label: Text("Reject", style: TextStyle(color: Colors.red)),
                        onPressed: () => _rejectReport(context, report.fileName),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        label: Text("Accept"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _acceptReport(context, report.fileName),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 13)),
      backgroundColor: Colors.grey.shade200,
      shape: StadiumBorder(),
    );
  }
}

class ATRReport {
  final String fileName;
  final String uploadedDate;
  final String officerName;
  final String fileSize;
  final String folder;

  ATRReport({
    required this.fileName,
    required this.uploadedDate,
    required this.officerName,
    required this.fileSize,
    required this.folder,
  });
}
