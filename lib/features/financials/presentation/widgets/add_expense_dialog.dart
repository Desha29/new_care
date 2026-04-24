import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cubit/financials_cubit.dart';

class AddExpenseDialog extends StatefulWidget {
  final FinancialsCubit cubit;

  const AddExpenseDialog({super.key, required this.cubit});

  static void show(BuildContext context, FinancialsCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(cubit: cubit),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'مرتبات';

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'إضافة مصروف جديد',
        style: TextStyle(fontFamily: 'Cairo'),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                'مرتبات',
                'إيجار',
                'مستلزمات طبية',
                'كهرباء ومياه',
                'صيانة',
                'أخرى',
              ]
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'التصنيف'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(labelText: 'الوصف أو البند'),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'مبلغ غير صحيح' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final user = FirebaseAuth.instance.currentUser;
              widget.cubit.addExpense(
                label: _labelCtrl.text.trim(),
                amount: double.parse(_amountCtrl.text),
                category: _category,
                notes: _noteCtrl.text.trim(),
                userId: user?.uid ?? 'system',
              );
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}
