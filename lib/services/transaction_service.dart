import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('transactions');

  /// Stream of all transactions, ordered by date descending.
  static Stream<QuerySnapshot> getTransactionsStream() {
    return _collection.orderBy('date', descending: true).snapshots();
  }

  /// Add a new transaction.
  static Future<void> addTransaction({
    required DateTime date,
    required String type,
    required String category,
    required double amount,
    String? details,
  }) {
    return _collection.add({
      'date': Timestamp.fromDate(date),
      'type': type,
      'category': category,
      'amount': amount,
      'details': details ?? '',
    });
  }

  /// Delete a transaction by its document ID.
  static Future<void> deleteTransaction(String docId) {
    return _collection.doc(docId).delete();
  }

  /// Get unique categories for a given type from existing transactions.
  static Future<List<String>> getCategoriesForType(String type) async {
    final snapshot = await _collection.where('type', isEqualTo: type).get();
    final categories = <String>{};
    for (final doc in snapshot.docs) {
      final cat = doc.data()['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    final sorted = categories.toList()..sort();
    return sorted;
  }

  /// Normalize the type field to one of: Income, Expenses, Savings.
  static String _normalizeType(String? raw) {
    if (raw == null || raw.isEmpty) return 'Expenses';
    final lower = raw.trim().toLowerCase();
    if (lower == 'income') return 'Income';
    if (lower == 'expense' || lower == 'expenses') return 'Expenses';
    if (lower == 'saving' || lower == 'savings') return 'Savings';
    return 'Expenses';
  }

  /// Helper: parse a Firestore document into a Map with typed fields.
  static Map<String, dynamic> parseDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime date;
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }
    return {
      'id': doc.id,
      'date': date,
      'type': _normalizeType(data['type'] as String?),
      'category': data['category'] ?? 'Uncategorized',
      'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
      'details': data['details'] ?? '',
    };
  }
}
