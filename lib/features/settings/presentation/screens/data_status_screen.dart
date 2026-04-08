import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/sqlite_service.dart';

class DataStatusScreen extends StatefulWidget {
  const DataStatusScreen({super.key});

  @override
  State<DataStatusScreen> createState() => _DataStatusScreenState();
}

class _DataStatusScreenState extends State<DataStatusScreen> {
  bool _isLoading = true;
  int _firestoreUsers = 0;
  int _firestorePatients = 0;
  int _sqliteUsers = 0;
  int _sqlitePatients = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        FirebaseService.instance.getUsersCount(),
        FirebaseService.instance.getPatientsCount(),
        SqliteService.instance.getUsersCount(),
        SqliteService.instance.getPatientsCount(),
      ]);

      setState(() {
        _firestoreUsers = futures[0];
        _firestorePatients = futures[1];
        _sqliteUsers = futures[2];
        _sqlitePatients = futures[3];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة مزامنة البيانات', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDataCard(
                    title: 'قاعدة البيانات السحابية (Firestore)',
                    icon: Icons.cloud_done_rounded,
                    color: Colors.blue,
                    users: _firestoreUsers,
                    patients: _firestorePatients,
                  ),
                  const SizedBox(height: 24),
                  _buildDataCard(
                    title: 'قاعدة البيانات المحلية (SQLite)',
                    icon: Icons.storage_rounded,
                    color: Colors.orange,
                    users: _sqliteUsers,
                    patients: _sqlitePatients,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'يتم استخدام قاعدة البيانات المحلية كنسخة احتياطية وللعمل في وضع عدم الاتصال.',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required Color color,
    required int users,
    required int patients,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildStatItem('المستخدمون', users, Icons.people, color),
              const SizedBox(width: 40),
              _buildStatItem('المرضى', patients, Icons.person, color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
