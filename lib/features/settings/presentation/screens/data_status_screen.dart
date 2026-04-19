import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/sqlite_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

class DataStatusScreen extends StatefulWidget {
  const DataStatusScreen({super.key});

  @override
  State<DataStatusScreen> createState() => _DataStatusScreenState();
}

class _DataStatusScreenState extends State<DataStatusScreen> {
  bool _isLoading = true;
  
  // Counts
  int _firestoreUsers = 0;
  int _firestorePatients = 0;
  int _firestoreShifts = 0;
  int _firestoreInventory = 0;
  int _firestoreProcedures = 0;
  
  int _sqliteUsers = 0;
  int _sqlitePatients = 0;
  int _sqliteShifts = 0;
  int _sqliteInventory = 0;
  int _sqliteProcedures = 0;
  
  int _pendingCount = 0;
  int _fbRead = 0;
  int _fbWrite = 0;

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
        FirebaseService.instance.getShiftsCount(),
        FirebaseService.instance.getInventoryCount(),
        FirebaseService.instance.getProceduresCount(),
        
        SqliteService.instance.getUsersCount(),
        SqliteService.instance.getPatientsCount(),
        SqliteService.instance.getShiftsCount(),
        SqliteService.instance.getInventoryCount(),
        SqliteService.instance.getProceduresCount(),
        
        SyncManager.instance.getPendingCount(),
      ]);

      setState(() {
        _firestoreUsers = futures[0];
        _firestorePatients = futures[1];
        _firestoreShifts = futures[2];
        _firestoreInventory = futures[3];
        _firestoreProcedures = futures[4];
        
        _sqliteUsers = futures[5];
        _sqlitePatients = futures[6];
        _sqliteShifts = futures[7];
        _sqliteInventory = futures[8];
        _sqliteProcedures = futures[9];
        
        _pendingCount = futures[10];
        _fbRead = FirebaseService.readCount;
        _fbWrite = FirebaseService.writeCount;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
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
            onPressed: () {
              FirebaseService.instance.resetStats();
              _loadData();
            }, 
            icon: const Icon(Icons.refresh_rounded)
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildUsageCard(),
                  const SizedBox(height: 20),
                  _buildSyncFlowCard(),
                  const SizedBox(height: 20),
                  _buildDataComparisonCard(
                    title: 'قاعدة البيانات السحابية (Firestore)',
                    icon: Icons.cloud_done_rounded,
                    color: Colors.blue,
                    users: _firestoreUsers,
                    patients: _firestorePatients,
                    shifts: _firestoreShifts,
                    inv: _firestoreInventory,
                    proc: _firestoreProcedures,
                  ),
                  const SizedBox(height: 20),
                  _buildDataComparisonCard(
                    title: 'قاعدة البيانات المحلية (SQLite)',
                    icon: Icons.storage_rounded,
                    color: Colors.orange,
                    users: _sqliteUsers,
                    patients: _sqlitePatients,
                    shifts: _sqliteShifts,
                    inv: _sqliteInventory,
                    proc: _sqliteProcedures,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'بدء مزامنة إجبارية',
                      icon: Icons.sync_rounded,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await SyncManager.instance.syncAll();
                        _loadData();
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUsageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.cyanAccent),
              SizedBox(width: 12),
              Text(
                'إحصائيات استخدام Firebase',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(_fbRead.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const Text('عمليات قراءة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Column(
                children: [
                  Text(_fbWrite.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  const Text('عمليات كتابة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFlowCard() {
    final bool isInSync = _pendingCount == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isInSync ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isInSync ? Colors.green.shade100 : Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(
            isInSync ? Icons.check_circle_outline_rounded : Icons.sync_problem_rounded,
            color: isInSync ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInSync ? 'البيانات متزامنة بالكامل' : 'يوجد عمليات قيد الانتظار',
                  style: TextStyle(
                    fontFamily: 'Cairo', 
                    fontWeight: FontWeight.bold,
                    color: isInSync ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  isInSync ? 'جميع التغييرات محفوظة سحابياً' : 'سيتم المزامنة تلقائياً عند استقرار الشبكة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isInSync ? Colors.green.shade600 : Colors.orange.shade600),
                ),
              ],
            ),
          ),
          if (!isInSync)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '$_pendingCount رقم',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataComparisonCard({
    required String title,
    required IconData icon,
    required Color color,
    required int users,
    required int patients,
    required int shifts,
    required int inv,
    required int proc,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildSmallStat('موظفين', users, Icons.people_outline, color),
              _buildSmallStat('مرضى', patients, Icons.person_outline, color),
              _buildSmallStat('ورديات', shifts, Icons.history_rounded, color),
              _buildSmallStat('مخزون', inv, Icons.inventory_2_outlined, color),
              _buildSmallStat('إجراءات', proc, Icons.medical_services_outlined, color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, int value, IconData icon, Color color) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(height: 6),
          Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
