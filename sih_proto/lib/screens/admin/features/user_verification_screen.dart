import 'package:flutter/material.dart';
import 'package:sih_proto/services/supabase_config.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({super.key});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  final SupabaseManager _supabaseManager = SupabaseManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      appBar: AppBar(
        title: const Text('User Verification'),
        backgroundColor: const Color(0xFF2d3748),
      ),
      body: StreamBuilder<List<UnverifiedUser>>(
        stream: _supabaseManager.getUnverifiedUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('No users pending verification.', style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: const Color(0xFF2d3748),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.white70),
                  title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email, style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                        onPressed: () => _supabaseManager.verifyUser(user.id),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () => _supabaseManager.deleteUser(user.id),
                        tooltip: 'Reject & Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
