import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/inventory_model.dart';

class InventoryFormDialog extends StatefulWidget {
  final InventoryModel? item;
  final Function(InventoryModel) onSave;

  const InventoryFormDialog({super.key, this.item, required this.onSave});

  static void show(BuildContext context, {InventoryModel? item, required Function(InventoryModel) onSave}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InventoryFormDialog(item: item, onSave: onSave),
    );
  }

  @override
  State<InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _unitCtrl;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _qtyCtrl = TextEditingController(text: widget.item?.quantity.toString() ?? '');
    _minCtrl = TextEditingController(text: widget.item?.minStock.toString() ?? '5');
    _priceCtrl = TextEditingController(text: widget.item?.price.toString() ?? '');
    _categoryCtrl = TextEditingController(text: widget.item?.category ?? '');
    _unitCtrl = TextEditingController(text: widget.item?.unit ?? 'قطعة');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? AppStrings.editItem : AppStrings.addItem,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field('اسم المستلزم', _nameCtrl, Icons.inventory_2_rounded, isRequired: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field('التصنيف', _categoryCtrl, Icons.category_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('الوحدة', _unitCtrl, Icons.scale_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'الكمية الحالية',
                        _qtyCtrl,
                        Icons.numbers_rounded,
                        isNumber: true,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'الحد الأدنى',
                        _minCtrl,
                        Icons.warning_rounded,
                        isNumber: true,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  'سعر الوحدة',
                  _priceCtrl,
                  Icons.attach_money_rounded,
                  isNumber: true,
                  isRequired: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          AppStrings.cancel,
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final newItem = InventoryModel(
                              id: widget.item?.id ?? const Uuid().v4(),
                              name: _nameCtrl.text.trim(),
                              category: _categoryCtrl.text.trim(),
                              unit: _unitCtrl.text.trim(),
                              quantity: int.tryParse(_qtyCtrl.text) ?? 0,
                              minStock: int.tryParse(_minCtrl.text) ?? 5,
                              price: double.tryParse(_priceCtrl.text) ?? 0,
                              createdAt: widget.item?.createdAt ?? DateTime.now(),
                              updatedAt: DateTime.now(),
                              createdBy: widget.item?.createdBy ??
                                  FirebaseAuth.instance.currentUser?.uid ??
                                  '',
                            );
                            widget.onSave(newItem);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          AppStrings.save,
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}
