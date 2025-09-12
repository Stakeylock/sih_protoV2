import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_proto/providers/app_state.dart';
import 'package:sih_proto/services/database_service.dart';
import 'package:sih_proto/utils/app_theme.dart';

class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.currentUser?.id;
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Digital ID')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: userId == null
            ? const Center(child: Text('User not found.'))
            : FutureBuilder<Map<String, dynamic>?>(
                future: dbService.getDigitalId(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('Could not load Digital ID.'));
                  }

                  final digitalId = snapshot.data!;
                  final userName = appState.userProfile?['full_name'] ?? 'N/A';
                  
                  return Center(
                    child: AspectRatio(
                      aspectRatio: 85.60 / 53.98, // Credit card aspect ratio
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentColor, Colors.cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOURIST DIGITAL ID',
                                style: TextStyle(
                                  color: AppTheme.primaryColor.withOpacity(0.7),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                userName.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildIdRow('DOC TYPE', digitalId['document_type'] ?? 'N/A'),
                              _buildIdRow('VALID UNTIL', digitalId['valid_until'] != null ? digitalId['valid_until'].toString().substring(0, 10) : 'N/A'),
                              const Spacer(),
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(Icons.qr_code_2, size: 40, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildIdRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.primaryColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

