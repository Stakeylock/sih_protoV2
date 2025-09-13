import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();
  late Future<List<UserProfile>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _supabaseManager.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _supabaseManager.getAllUsers();
    });
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _supabaseManager.updateUserRole(userId: userId, newRole: newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated successfully!'), backgroundColor: Colors.green),
      );
      _refreshUsers(); // Refresh the list to show the change
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRoleChangeDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: Text('Change Role for ${user.fullName}', style: const TextStyle(color: Colors.white)),
          content: DropdownButton<String>(
            value: selectedRole,
            dropdownColor: const Color(0xFF2d3748),
            style: const TextStyle(color: Colors.white),
            items: ['Tourist', 'Police', 'Admin'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                selectedRole = newValue;
                // A bit of a hack to make the dialog's stateful widget update
                (context as StatefulElement).markNeedsBuild();
              }
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateUserRole(user.id, selectedRole);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1a202c),
      body: FutureBuilder<List<UserProfile>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white70)));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: const Color(0xFF2d3748),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.white70),
                  title: Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(user.role, style: TextStyle(color: _getRoleColor(user.role))),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _showRoleChangeDialog(user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.redAccent;
      case 'Police':
        return Colors.blueAccent;
      case 'Tourist':
      default:
        return Colors.greenAccent;
    }
  }
}

