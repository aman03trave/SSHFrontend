import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: NewGrievancePage()));
}

class NewGrievancePage extends StatelessWidget {
  const NewGrievancePage({super.key});

  final List<GrievanceItem> grievances = const [
    GrievanceItem(
      title: "No Drinking Water",
      subtitle: "Block B, Floor 2",
      duration: "2 hours ago",
      status: GrievanceStatus.completed,
    ),
    GrievanceItem(
      title: "Lights Not Working",
      subtitle: "Room 204, Building C",
      duration: "3 hours ago",
      status: GrievanceStatus.completed,
    ),
    GrievanceItem(
      title: "Window Issue",
      subtitle: "Library Reading Room",
      duration: "4 hours ago",
      status: GrievanceStatus.inProgress,
    ),
    GrievanceItem(
      title: "Slow Internet",
      subtitle: "Lab 1, CS Department",
      duration: "Just now",
      status: GrievanceStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("New Grievances"),
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Latest grievances submitted by users.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: grievances.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = grievances[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GrievanceDetailPage(item: item),
                        ),
                      );
                    },
                    child: _GrievanceTile(item: item, index: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GrievanceStatus { completed, inProgress, pending }

class GrievanceItem {
  final String title;
  final String subtitle;
  final String duration;
  final GrievanceStatus status;

  const GrievanceItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.status,
  });
}

class _GrievanceTile extends StatelessWidget {
  final GrievanceItem item;
  final int index;

  const _GrievanceTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final List<Color> tileColors = [
      const Color(0xFFE6F0FD), // blue tint
      const Color(0xFFE0F7FA), // water tint
      const Color(0xFFFFF8E1), // cream
    ];

    final Color backgroundColor = tileColors[index % tileColors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            item.duration,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class GrievanceDetailPage extends StatelessWidget {
  final GrievanceItem item;

  const GrievanceDetailPage({super.key, required this.item});

  String getStatusText(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.completed:
        return "Completed";
      case GrievanceStatus.inProgress:
        return "In Progress";
      case GrievanceStatus.pending:
        return "Pending";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grievance Details"),
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("📍 Location: ${item.subtitle}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🕒 Submitted: ${item.duration}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("📌 Status: ${getStatusText(item.status)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              "This is a placeholder for the grievance description. Detailed info about the issue can be shown here.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
