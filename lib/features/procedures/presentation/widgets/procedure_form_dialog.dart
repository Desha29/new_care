import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/procedure_model.dart';
import '../cubit/procedures_cubit.dart';

class ProcedureFormDialog extends StatefulWidget {
  final ProceduresCubit cubit;
  final ProcedureModel? item;

  const ProcedureFormDialog({super.key, required this.cubit, this.item});

  static void show(BuildContext context, ProceduresCubit cubit, {ProcedureModel? item}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProcedureFormDialog(cubit: cubit, item: item),
    );
  }

  @override
  State<ProcedureFormDialog> createState() => _ProcedureFormDialogState();
}

class _ProcedureFormDialogState extends State<ProcedureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceInsideCtrl;
  late final TextEditingController _priceOutsideCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _priceInsideCtrl = TextEditingController(text: widget.item?.priceInside.toString() ?? '');
    _priceOutsideCtrl = TextEditingController(text: widget.item?.priceOutside.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.item?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceInsideCtrl.dispose();
    _priceOutsideCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: _isSaving
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isEdit),
                    const SizedBox(height: 24),
                    _buildField('اسم الخدمة / الإجراء', _nameCtrl, Icons.medical_services_rounded, isRequired: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('سعر الداخل', _priceInsideCtrl, Icons.add_home_work_rounded, isNumber: true, isRequired: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('سعر الخارج', _priceOutsideCtrl, Icons.home_rounded, isNumber: true, isRequired: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('ملاحظات', _notesCtrl, Icons.notes_rounded, maxLines: 3),
                    const SizedBox(height: 30),
                    _buildActions(isEdit),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEdit ? Icons.edit_rounded : Icons.post_add_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'تعديل الخدمة/الإجراء' : 'إضافة خدمة/إجراء جديد',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
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

  Widget _buildActions(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() => _isSaving = true);
                try {
                  final newItem = ProcedureModel(
                    id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameCtrl.text.trim(),
                    priceInside: double.tryParse(_priceInsideCtrl.text) ?? 0,
                    priceOutside: double.tryParse(_priceOutsideCtrl.text) ?? 0,
                    defaultPrice: double.tryParse(_priceInsideCtrl.text) ?? 0,
                    notes: _notesCtrl.text.trim(),
                    updatedAt: DateTime.now(),
                  );

                  await widget.cubit.addProcedure(newItem);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) setState(() => _isSaving = false);
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
    );
  }
}

