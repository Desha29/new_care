import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../data/models/procedure_model.dart';

class ProceduresScreen extends StatefulWidget {
  const ProceduresScreen({super.key});

  @override
  State<ProceduresScreen> createState() => _ProceduresScreenState();
}

class _ProceduresScreenState extends State<ProceduresScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  List<ProcedureModel> _procedures = [];

  @override
  void initState() {
    super.initState();
    _loadProcedures();
  }

  Future<void> _loadProcedures() async {
    setState(() => _isLoading = true);
    try {
      final items = await FirebaseService.instance.getAllProcedures();
      if (mounted) {
        setState(() {
          _procedures = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجراءات والخدمات',
                style: AppTypography.pageTitle.copyWith(fontSize: 24),
              ),
              PrimaryButton(
                label: 'إضافة إجراء جديد',
                icon: Icons.add_rounded,
                onPressed: () => _showProcedureDialog(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SearchBarWidget(
                  controller: _searchCtrl,
                  hintText: 'ابحث عن الإجراء أو الخدمة...',
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : Builder(
              builder: (context) {
                final query = _searchCtrl.text.toLowerCase().trim();
                final filtered = _procedures.where((e) {
                  if (query.isEmpty) return true;
                  return e.name.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.medical_services_rounded,
                    title: 'لا توجد إجراءات',
                    subtitle: 'تأكد من اختيار إجراءات وإضافتها للنظام',
                    actionLabel: 'إضافة إجراء',
                    onAction: () => _showProcedureDialog(),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            _hc('م', 1),
                            _hc('اسم الإجراء', 3),
                            _hc('سعر الداخل', 2),
                            _hc('سعر الخارج', 2),
                            _hc('ملاحظات', 2),
                            _hc('إجراءات', 2),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                          itemBuilder: (context, index) => _buildRow(filtered[index], index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, style: AppTypography.tableHeader.copyWith(fontSize: 13)),
    );
  }

  Widget _buildRow(ProcedureModel item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: index.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14))),
          Expanded(
            flex: 3,
            child: Text(item.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.priceInside} ${AppStrings.currency}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.priceOutside} ${AppStrings.currency}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.notes.isEmpty ? '---' : item.notes,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconActionButton.edit(onPressed: () => _showProcedureDialog(item: item)),
                const SizedBox(width: 8),
                IconActionButton.delete(onPressed: () => _confirmDelete(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProcedureDialog({ProcedureModel? item}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceInsideCtrl = TextEditingController(text: item?.priceInside.toString() ?? '');
    final priceOutsideCtrl = TextEditingController(text: item?.priceOutside.toString() ?? '');
    final notesCtrl = TextEditingController(text: item?.notes ?? '');
    final isEdit = item != null;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(28),
            child: isSaving
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(isEdit ? Icons.edit_rounded : Icons.post_add_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEdit ? 'تعديل الخدمة/الإجراء' : 'إضافة خدمة/إجراء جديد',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _dialogField('اسم الخدمة / الإجراء', nameCtrl, Icons.medical_services_rounded, isRequired: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _dialogField('سعر الداخل', priceInsideCtrl, Icons.add_home_work_rounded, isNumber: true, isRequired: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _dialogField('سعر الخارج', priceOutsideCtrl, Icons.home_rounded, isNumber: true, isRequired: true)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _dialogField('ملاحظات', notesCtrl, Icons.notes_rounded, maxLines: 3),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState?.validate() ?? false) {
                                    ss(() => isSaving = true);
                                    try {
                                      final newItem = ProcedureModel(
                                        id: item?.id == null || item!.id.isEmpty ? FirebaseService.instance.generateId() : item.id,
                                        name: nameCtrl.text.trim(),
                                        priceInside: double.tryParse(priceInsideCtrl.text) ?? 0,
                                        priceOutside: double.tryParse(priceOutsideCtrl.text) ?? 0,
                                        defaultPrice: double.tryParse(priceInsideCtrl.text) ?? 0, // Fallback for old compatibility
                                        notes: notesCtrl.text.trim(),
                                      );

                                      if (isEdit) {
                                        await FirebaseService.instance.updateProcedure(newItem);
                                      } else {
                                        await FirebaseService.instance.createProcedure(newItem);
                                      }
                                      if (mounted) {
                                        Navigator.pop(ctx);
                                        _loadProcedures();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isEdit ? 'تم تحديث الإجراء بنجاح' : 'تم إضافة الإجراء بنجاح', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
                                        );
                                      }
                                    } catch (e) {
                                      ss(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.error));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            if (isRequired) const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(ProcedureModel item) async {
    final res = await ConfirmDialog.show(
      context,
      title: 'حذف الإجراء',
      message: 'هل أنت متأكد من حذف الإجراء "${item.name}"؟',
      confirmText: AppStrings.delete,
      icon: Icons.delete_forever_rounded,
    );

    if (res == true) {
      try {
        await FirebaseService.instance.deleteProcedure(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الإجراء بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
          );
          _loadProcedures();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.error));
        }
      }
    }
  }
}
