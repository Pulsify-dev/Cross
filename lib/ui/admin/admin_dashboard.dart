import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Load analytics and initial user list on startup
    Future.microtask(() => context.read<AdminProvider>().fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("PULSIFY COMMAND", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildAnalyticsHeader(admin.stats),
                _buildViewToggle(admin),
                const Divider(color: Colors.white12, height: 1),
                Expanded(child: _buildMainList(admin)),
              ],
            ),
    );
  }

  // --- ANALYTICS SECTION (Screenshot 13) ---
  Widget _buildAnalyticsHeader(Map? stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.orange.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Users", stats?['total_users']?.toString() ?? "0"),
          _statItem("Tracks", stats?['total_tracks']?.toString() ?? "0"),
          _statItem("Albums", stats?['total_albums']?.toString() ?? "0"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // --- VIEW TOGGLE (Users / Tracks / Albums) ---
  Widget _buildViewToggle(AdminProvider admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['users', 'tracks', 'albums'].map((view) {
          bool isActive = admin.currentView == view;
          return ChoiceChip(
            label: Text(view.toUpperCase()),
            selected: isActive,
            onSelected: (_) => admin.setView(view),
            selectedColor: Colors.orange,
            backgroundColor: Colors.grey[900],
            labelStyle: TextStyle(color: isActive ? Colors.black : Colors.white),
          );
        }).toList(),
      ),
    );
  }

  // --- THE LIST WITH BUTTONS (Screenshots 4-12, 14-16) ---
  Widget _buildMainList(AdminProvider admin) {
    if (admin.items.isEmpty) {
      return const Center(child: Text("No items found", style: TextStyle(color: Colors.white)));
    }

    return ListView.builder(
      itemCount: admin.items.length,
      itemBuilder: (context, i) {
        final item = admin.items[i];
        final String title = item['name'] ?? item['title'] ?? "Unknown";
        final String subTitle = item['email'] ?? "ID: ${item['_id']?.toString().substring(0, 8)}...";

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[900],
            child: Icon(_getIcon(admin.currentView), color: Colors.orange, size: 20),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(subTitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.orange),
            color: const Color(0xFF1E1E1E),
            onSelected: (action) => _handleMenuAction(action, item, admin),
            itemBuilder: (context) => _buildMenuOptions(admin.currentView, item),
          ),
        );
      },
    );
  }

  List<PopupMenuEntry<String>> _buildMenuOptions(String view, dynamic item) {
    if (view == 'users') {
      bool isSuspended = item['isSuspended'] ?? false;
      return [
        PopupMenuItem(
          value: 'suspend',
          child: Text(isSuspended ? 'Restore User' : 'Suspend User', 
                style: TextStyle(color: isSuspended ? Colors.green : Colors.redAccent)),
        ),
        const PopupMenuItem(value: 'role', child: Text('Promote to Admin', style: TextStyle(color: Colors.white))),
      ];
    } else {
      return [
        const PopupMenuItem(value: 'block', child: Text('Toggle Block', style: TextStyle(color: Colors.yellow))),
        const PopupMenuItem(value: 'delete', child: Text('Delete Permanent', style: TextStyle(color: Colors.redAccent))),
      ];
    }
  }

  void _handleMenuAction(String action, dynamic item, AdminProvider admin) {
    final id = item['_id'];
    if (action == 'suspend') {
      admin.handleUserStatus(id, item['isSuspended'] ?? false);
    } else if (action == 'delete') {
      admin.removeContent(id, admin.currentView == 'tracks');
    }
    // Logic for role changes and blocking would go here
  }

  IconData _getIcon(String view) {
    switch (view) {
      case 'users': return Icons.person_outline;
      case 'tracks': return Icons.music_note_outlined;
      default: return Icons.album_outlined;
    }
  }
}