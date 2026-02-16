import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/transaction_service.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  final _newCategoryController = TextEditingController();

  String _type = 'Expenses';
  String? _category;
  bool _isNewCategory = false;
  DateTime _selectedDate = DateTime.now();
  List<String> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await TransactionService.getFrequentTransactions();
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _loadingSuggestions = false;
      });
    }
  }

  void _applySuggestion(Map<String, dynamic> s) {
    setState(() {
      _type = s['type'] as String;
      _amountController.text = (s['amount'] as double).toStringAsFixed(2);
    });
    // Reload categories for the new type, then select the right one
    TransactionService.getCategoriesForType(_type).then((cats) {
      if (mounted) {
        setState(() {
          _categories = cats;
          final cat = s['category'] as String;
          if (cats.contains(cat)) {
            _category = cat;
            _isNewCategory = false;
          } else {
            _isNewCategory = true;
            _newCategoryController.text = cat;
          }
          _loadingCategories = false;
        });
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final cats = await TransactionService.getCategoriesForType(_type);
    setState(() {
      _categories = cats;
      _category = cats.isNotEmpty ? cats.first : null;
      _isNewCategory = cats.isEmpty;
      _loadingCategories = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF48BB78),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Color(0xFFFC8181)),
      );
      return;
    }

    final category = _isNewCategory ? _newCategoryController.text.trim() : _category;
    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a category'), backgroundColor: Color(0xFFFC8181)),
      );
      return;
    }

    setState(() => _saving = true);

    await TransactionService.addTransaction(
      date: _selectedDate,
      type: _type,
      category: category,
      amount: amount,
      details: _detailsController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Added: $_type · $category · €${amount.toStringAsFixed(2)}'),
          backgroundColor: const Color(0xFF48BB78),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text('📝 New Transaction',
              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Quick suggestions
            if (!_loadingSuggestions && _suggestions.isNotEmpty) ...[
              const Text('⚡ Suggerimenti rapidi',
                style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  final type = s['type'] as String;
                  final color = type == 'Income'
                      ? const Color(0xFF48BB78)
                      : type == 'Savings'
                          ? const Color(0xFF63B3ED)
                          : const Color(0xFFFC8181);
                  final icon = type == 'Income' ? '💵' : type == 'Savings' ? '🏦' : '🔻';
                  return GestureDetector(
                    onTap: () => _applySuggestion(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$icon ${s['category']} · €${(s['amount'] as double).toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Date picker
            _label('📅 Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: _inputDecoration(),
                child: Row(
                  children: [
                    Text(DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15)),
                    const Spacer(),
                    const Icon(Icons.calendar_today, color: Color(0xFFA0AEC0), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type selector
            _label('📁 Type'),
            const SizedBox(height: 8),
            Row(
              children: ['Income', 'Expenses', 'Savings'].map((t) {
                final isSelected = _type == t;
                final color = t == 'Income' ? const Color(0xFF48BB78) : t == 'Expenses' ? const Color(0xFFFC8181) : const Color(0xFF63B3ED);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t != 'Savings' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _type = t);
                        _loadCategories();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Center(
                          child: Text(t, style: TextStyle(
                            color: isSelected ? color : const Color(0xFFA0AEC0),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category
            _label('🏷️ Category'),
            const SizedBox(height: 8),
            if (_loadingCategories)
              const LinearProgressIndicator(color: Color(0xFF48BB78))
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _inputDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _isNewCategory ? '___new___' : _category,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15),
                    items: [
                      ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      const DropdownMenuItem(value: '___new___', child: Text('➕ New category…', style: TextStyle(color: Color(0xFF48BB78)))),
                    ],
                    onChanged: (v) {
                      setState(() {
                        if (v == '___new___') {
                          _isNewCategory = true;
                          _category = null;
                        } else {
                          _isNewCategory = false;
                          _category = v;
                        }
                      });
                    },
                  ),
                ),
              ),
              if (_isNewCategory) ...[
                const SizedBox(height: 8),
                _textField(_newCategoryController, 'New category name', Icons.add_circle_outline),
              ],
            ],
            const SizedBox(height: 16),

            // Amount
            _label('💶 Amount (€)'),
            const SizedBox(height: 8),
            _textField(_amountController, '0.00', Icons.euro, isNumber: true),
            const SizedBox(height: 16),

            // Details
            _label('📝 Details (optional)'),
            const SizedBox(height: 8),
            _textField(_detailsController, 'e.g. Monthly salary…', Icons.notes),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('✅ Add Transaction'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13, fontWeight: FontWeight.w500));
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    );
  }

  Widget _textField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: _inputDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
          prefixIcon: Icon(icon, color: const Color(0xFFA0AEC0), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}