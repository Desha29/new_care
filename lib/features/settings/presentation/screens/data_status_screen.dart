import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/sync/outside_cases_listener.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../cases/presentation/cubit/cases_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../procedures/presentation/cubit/procedures_cubit.dart';
import '../../../financials/presentation/cubit/financials_cubit.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../../core/widgets/sync_progress_dialog.dart';


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

  // Subscriptions for auto-refresh
  StreamSubscription? _caseChangeSub;
  StreamSubscription? _dataChangeSub;

  @override
  void initState() {
    super.initState();
    _loadData();

    // الاستماع لتغييرات الحالات - Listen for case changes
    _caseChangeSub = CaseChangeNotifier().onCaseChanged.listen((_) {
      _loadLocalCounts();
    });

    // الاستماع لتغييرات البيانات (مستخدمين، مخزون، إجراءات) - Listen for data changes
    _dataChangeSub = DataChangeNotifier().onDataChanged.listen((_) {
      _loadLocalCounts();
    });
  }

  @override
  void dispose() {
    _caseChangeSub?.cancel();
    _dataChangeSub?.cancel();
    super.dispose();
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

  /// تحديث الأعداد المحلية فقط (بدون إعادة جلب بيانات السحابة)
  /// Fast refresh of local SQLite counts + pending count only
  Future<void> _loadLocalCounts() async {
    try {
      final futures = await Future.wait([
        SqliteService.instance.getUsersCount(),
        SqliteService.instance.getPatientsCount(),
        SqliteService.instance.getShiftsCount(),
        SqliteService.instance.getInventoryCount(),
        SqliteService.instance.getProceduresCount(),
        SyncManager.instance.getPendingCount(),
      ]);

      if (mounted) {
        setState(() {
          _sqliteUsers = futures[0];
          _sqlitePatients = futures[1];
          _sqliteShifts = futures[2];
          _sqliteInventory = futures[3];
          _sqliteProcedures = futures[4];
          _pendingCount = futures[5];
        });
      }
    } catch (e) {
      // Silent fail for background refresh
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
                  const SizedBox(height: 16),
                  _buildTestOutsideCaseButton(),
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
            color: Colors.black.withOpacity(0.05),
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
                SyncProgressDialog.show(context, title: 'مزامنة شاملة');
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
          colors: [AppColors.primaryDark, AppColors.primary.withOpacity(0.8)],
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
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
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
    return Row(
      children: [
        // زر رفع البيانات للسحابة - Upload to Cloud
        Expanded(
          child: PrimaryButton(
            label: 'مزامنة إجبارية شاملة',
            icon: Icons.cloud_upload_rounded,
            onPressed: _isLoading
                ? null
                : () async {
                    try {
                      // عرض ديالوج التقدم
                      SyncProgressDialog.show(context, title: 'مزامنة شاملة');
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
                        // Close dialog if still open
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
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
                    }
                  },
          ),
        ),
        const SizedBox(width: 16),
        // زر تحميل من السحابة - Download from Cloud
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download_rounded, color: Colors.white),
            label: const Text(
              'تحميل من السحابة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading
                ? null
                : () async {
                    try {
                      // عرض ديالوج التقدم
                      SyncProgressDialog.show(context, title: 'تحميل من السحابة');
                      await SyncManager.instance.downloadFromCloud();
                      await _loadData();


                      // === تحديث جميع الشاشات بعد التحميل من السحابة ===
                      if (mounted) {
                        context.read<CasesCubit>().loadCases(force: true);
                        context.read<InventoryCubit>().loadInventory(
                          force: true,
                        );
                        context.read<ProceduresCubit>().loadProcedures(
                          force: true,
                        );
                        context.read<FinancialsCubit>().loadFinancials(
                          force: true,
                        );
                        context.read<DashboardCubit>().loadDashboardData(
                          force: true,
                        );
                      }

                      CaseChangeNotifier().notifyCaseUpdated('cloud_download');
                      DataChangeNotifier().notifyCloudDownloadCompleted();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تحميل البيانات من السحابة بنجاح',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'خطأ في التحميل: $e',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildTestOutsideCaseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.science_rounded, color: Colors.white),
        label: const Text(
          'إضافة حالة تجريبية خارجية (outside_cases)',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                try {
                  await OutsideCasesListener.instance.addFakeTestCase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم إضافة حالة تجريبية في outside_cases — سيتم استيرادها تلقائياً',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.deepOrange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'خطأ: $e',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
      ),
    );
  }
}
