import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  String _selectedType = 'Expense';
  String _selectedCategory = 'Spesa';

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    FirebaseFirestore.instance.collection('transactions').add({
      'amount': amount,
      'type': _selectedType,
      'category': _selectedCategory,
      'date': DateTime.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Importo (€)'),
          ),
          DropdownButton<String>(
            value: _selectedType,
            isExpanded: true,
            items: ['Income', 'Expense'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveTransaction,
            child: const Text('Salva Transazione'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}