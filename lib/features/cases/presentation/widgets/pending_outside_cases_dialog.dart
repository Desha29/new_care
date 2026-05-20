import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/sync/outside_cases_listener.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/case_model.dart';
import '../../../../core/enums/case_status.dart';

class PendingOutsideCasesDialog extends StatefulWidget {
  const PendingOutsideCasesDialog({super.key});

  @override
  State<PendingOutsideCasesDialog> createState() => _PendingOutsideCasesDialogState();
}

class _PendingOutsideCasesDialogState extends State<PendingOutsideCasesDialog> {
  String? _processingCaseId;

  Future<void> _approveCase(QueryDocumentSnapshot doc) async {
    final pendingList = OutsideCasesListener.instance.pendingCasesNotifier.value;
    final isLastCase = pendingList.length <= 1;

    setState(() => _processingCaseId = doc.id);
    try {
      final result = await OutsideCasesListener.instance.processCase(doc);
      if (mounted) {
        if (result['success'] == true) {
          UIFeedback.showSuccess(context, result['message'] ?? 'تم حفظ الحالة بنجاح');
          if (isLastCase) {
            Navigator.pop(context); // Close dialog only if it was the last case
          }
        } else {
          // Insufficient stock or other business errors
          _showErrorAlert(result['message'] ?? 'فشل في حفظ الحالة');
        }
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, 'خطأ أثناء المعالجة: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _processingCaseId = null);
      }
    }
  }

  Future<void> _deleteCase(QueryDocumentSnapshot doc) async {
    final pendingList = OutsideCasesListener.instance.pendingCasesNotifier.value;
    final isLastCase = pendingList.length <= 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'حذف الحالة الخارجية',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذه الحالة الخارجية المعلقة؟ لن يتم حفظها في النظام وسوف تُحذف نهائياً.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('حذف نهائي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _processingCaseId = doc.id);
      try {
        await FirebaseFirestore.instance.collection('outside_cases').doc(doc.id).delete();
        if (mounted) {
          UIFeedback.showInfo(context, 'تم حذف الحالة الخارجية المعلقة بنجاح');
          if (isLastCase) {
            Navigator.pop(context); // Close dialog only if it was the last case
          }
        }
      } catch (e) {
        if (mounted) {
          UIFeedback.showError(context, 'خطأ أثناء الحذف: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _processingCaseId = null);
        }
      }
    }
  }

  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 8),
              Text(
                'عذرًا، تعذر حفظ الحالة',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'الحالات الخارجية المعلقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'مراجعة واعتماد الحالات الطبية المرسلة من تطبيق الهواتف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              
              // Stream/Value Listenable Builder of pending cases
              Expanded(
                child: ValueListenableBuilder<List<QueryDocumentSnapshot>>(
                  valueListenable: OutsideCasesListener.instance.pendingCasesNotifier,
                  builder: (context, docs, child) {
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.statusCompletedBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.done_all_rounded, color: AppColors.statusCompleted, size: 48),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد حالات معلقة حالياً!',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'سيظهر هنا أي حالة جديدة يتم إضافتها من قبل الممرضين عبر تطبيق الجوال.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        CaseModel? caseModel;
                        try {
                          caseModel = CaseModel.fromMap(data, doc.id);
                        } catch (e) {
                          // Fail-safe if data format is corrupt
                        }

                        if (caseModel == null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.statusCancelledBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.statusCancelled),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'خطأ في قراءة بيانات الحالة المعلقة (${doc.id})',
                                    style: const TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                  onPressed: () => _deleteCase(doc),
                                ),
                              ],
                            ),
                          );
                        }

                        final isProcessing = _processingCaseId == doc.id;
                        final dateStr = intl.DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(caseModel.caseDate);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Patient Name & Case Type row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person_rounded, color: AppColors.secondary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        caseModel.patientName,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Age/Gender chip
                                      Text(
                                        '(${caseModel.patientGenderLabel} - ${caseModel.patientAge} سنة)',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Case Type Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: caseModel.caseType == CaseType.homeVisit
                                          ? AppColors.secondary.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      caseModel.caseType == CaseType.homeVisit ? 'زيارة منزلية 🏠' : 'داخل المركز 🏥',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: caseModel.caseType == CaseType.homeVisit
                                            ? AppColors.secondaryDark
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Info Details Grid
                              Wrap(
                                spacing: 20,
                                runSpacing: 8,
                                children: [
                                  _infoTile(Icons.phone_rounded, 'الهاتف:', caseModel.patientPhone.isNotEmpty ? caseModel.patientPhone : 'غير مسجل'),
                                  if (caseModel.caseType == CaseType.homeVisit && caseModel.patientAddress.isNotEmpty)
                                    _infoTile(Icons.location_on_rounded, 'العنوان:', caseModel.patientAddress),
                                  _infoTile(Icons.badge_rounded, 'الممرض:', caseModel.nurseName),
                                  _infoTile(Icons.calendar_month_rounded, 'التاريخ:', dateStr),
                                ],
                              ),
                              const Divider(height: 20),

                              // Services / Procedures section
                              if (caseModel.services.isNotEmpty) ...[
                                const Text(
                                  'الخدمات والإجراءات الطبية:',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: caseModel.services.map((svc) {
                                    return Chip(
                                      label: Text(
                                        '${svc.name} (${svc.price.toStringAsFixed(0)} ج.م)',
                                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                                      ),
                                      backgroundColor: AppColors.surfaceVariant,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Supplies Used section
                              if (caseModel.suppliesUsed.isNotEmpty) ...[
                                const Text(
                                  'المستلزمات المستخدمة:',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: caseModel.suppliesUsed.map((sup) {
                                    return Chip(
                                      label: Text(
                                        '${sup.name} × ${sup.quantity}',
                                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textPrimary),
                                      ),
                                      backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Price & Action Button Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Total Price
                                  Row(
                                    children: [
                                      const Text(
                                        'الإجمالي: ',
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '${caseModel.totalPrice.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Actions
                                  Row(
                                    children: [
                                      // Delete/Reject Case
                                      OutlinedButton.icon(
                                        onPressed: isProcessing ? null : () => _deleteCase(doc),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                        label: const Text('رفض / حذف', style: TextStyle(fontFamily: 'Cairo')),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Approve & Save Case
                                      ElevatedButton.icon(
                                        onPressed: isProcessing ? null : () => _approveCase(doc),
                                        icon: isProcessing
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Icon(Icons.check_circle_outline_rounded, size: 16),
                                        label: Text(
                                          isProcessing ? 'جاري الحفظ...' : 'اعتماد وحفظ',
                                          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
