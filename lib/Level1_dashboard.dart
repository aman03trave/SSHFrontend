import 'package:flutter/material.dart';
import 'Level1_newgrievance.dart';
import 'AssignToLevel2Page.dart';
import 'profile.dart';
import 'ATRverify.dart';
void main() {
  runApp(const GrievanceApp());
}

class GrievanceApp extends StatelessWidget {
  const GrievanceApp({super.key});

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
      home: const GrievanceDashboard(),
    );
  }
}

class GrievanceDashboard extends StatefulWidget {
  const GrievanceDashboard({super.key});

  @override
  State<GrievanceDashboard> createState() => _GrievanceDashboardState();
}

class _GrievanceDashboardState extends State<GrievanceDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    DummyPage("Feed"),
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
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
            color: Colors.black,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Text(
            'Hello, Gagan 👋',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by title, date or status...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Trending section
          const Text(
            'Latest Grievance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: PageView(
              controller: PageController(viewportFraction: 0.9),
              children: const [
                _TrendingCard(
                  title: 'Govt Announced Free Electricity',
                  date: 'Apr 08, 2025',
                ),
                _TrendingCard(
                  title: 'New Digital Complaint Process Launched',
                  date: 'Apr 07, 2025',
                ),
              ],
            ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewGrievancePage()),
                ),
              ),
              _ServiceCard(
                icon: Icons.assignment,
                label: "Assign to Level 2",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignToLevel2Page()),
                ),
              ),
              _ServiceCard(
                icon: Icons.block,
                label: "Rejected",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DummyPage("Rejected")),
                ),
              ),
              _ServiceCard(
                icon: Icons.fact_check,
                label: "ATR Report",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ATRReportPage()),
                ),
              ),
              _ServiceCard(
                icon: Icons.task,
                label: "Assigned",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DummyPage("Assigned")),
                ),
              ),
              _ServiceCard(
                icon: Icons.verified,
                label: "Disposed",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DummyPage("Disposed")),
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

// Trending Card
class _TrendingCard extends StatelessWidget {
  final String title;
  final String date;
  const _TrendingCard({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
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