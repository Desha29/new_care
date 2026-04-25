import 'package:flutter/material.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/constants/app_colors.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'المزامنة والبيانات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseService.instance.resetStats();
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildSyncDashboard(),
                  const SizedBox(height: 24),
                  _buildUsageCard(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDataCard(
                          title: 'السحابة (Cloud)',
                          subtitle: 'قاعدة بيانات Firestore Live',
                          icon: Icons.cloud_outlined,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          users: _firestoreUsers,
                          patients: _firestorePatients,
                          shifts: _firestoreShifts,
                          inv: _firestoreInventory,
                          proc: _firestoreProcedures,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildDataCard(
                          title: 'المحلية (Local)',
                          subtitle: 'قاعدة بيانات SQLite المدمجة',
                          icon: Icons.cell_tower_rounded,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.secondaryDark,
                            ],
                          ),
                          users: _sqliteUsers,
                          patients: _sqlitePatients,
                          shifts: _sqliteShifts,
                          inv: _sqliteInventory,
                          proc: _sqliteProcedures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSyncButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncDashboard() {
    final bool isInSync = _pendingCount == 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isInSync
                  ? AppColors.statusCompletedBg
                  : AppColors.statusPendingBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInSync ? Icons.done_all_rounded : Icons.sync_problem_rounded,
              color: isInSync
                  ? AppColors.statusCompleted
                  : AppColors.statusPending,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInSync
                      ? 'كافة البيانات متزامنة'
                      : 'انتظار المزامنة المحلية',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isInSync
                      ? 'جميع التغييرات تم حفظها بأمان في السحابة'
                      : 'يوجد $_pendingCount عملية تنتظر المزامنة التلقائية',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isInSync)
            PrimaryButton(
              label: 'مزامنة الآن',
              onPressed: () async {
                setState(() => _isLoading = true);
                await SyncManager.instance.syncAll();
                _loadData();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUsageCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildUsageStat(
            'قراءات السحابة',
            _fbRead,
            Icons.visibility_outlined,
            Colors.cyanAccent,
          ),
          Container(width: 1, height: 50, color: Colors.white12),
          _buildUsageStat(
            'كتابات السحابة',
            _fbWrite,
            Icons.create_rounded,
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStat(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required int users,
    required int patients,
    required int shifts,
    required int inv,
    required int proc,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataRow(
            Icons.groups_outlined,
            'الموظفين',
            users,
            AppColors.primary,
          ),
          const Divider(height: 16),
          _buildDataRow(
            Icons.person_pin_rounded,
            'المرضى',
            patients,
            AppColors.info,
          ),
          const Divider(height: 16),
          _buildDataRow(
            Icons.event_note_rounded,
            'الورديات',
            shifts,
            AppColors.secondary,
          ),
          const Divider(height: 16),
          _buildDataRow(
            Icons.inventory_2_outlined,
            'المخزون',
            inv,
            Colors.purple,
          ),
          const Divider(height: 16),
          _buildDataRow(
            Icons.medical_services_outlined,
            'الإجراءات',
            proc,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        label: 'مزامنة إجبارية شاملة',
        icon: Icons.sync_rounded,
        onPressed: _isLoading
            ? null
            : () async {
                try {
                  setState(() => _isLoading = true);
                  await SyncManager.instance.syncAll();
                  await _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تمت المزامنة بنجاح',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'خطأ في المزامنة: $e',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
      ),
    );
  }
}
