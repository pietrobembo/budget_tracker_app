import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_transaction.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I miei Movimenti')),
      body: Column(
        children: [
          _buildBalanceCard(),
          const Expanded(child: TransactionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        double total = 0;
        for (var doc in snapshot.data!.docs) {
          double amount = doc['amount'];
          doc['type'] == 'Income' ? total += amount : total -= amount;
        }

        return Card(
          margin: const EdgeInsets.all(16),
          color: Colors.teal,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Saldo Totale', style: TextStyle(color: Colors.white70)),
                Text('€ ${total.toStringAsFixed(2)}', 
                     style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTransactionSheet(),
    );
  }
}

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            bool isIncome = doc['type'] == 'Income';
            return ListTile(
              leading: Icon(isIncome ? Icons.add_circle : Icons.remove_circle, 
                            color: isIncome ? Colors.green : Colors.red),
              title: Text(doc['category']),
              trailing: Text('€ ${doc['amount']}', 
                             style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),
            );
          }).toList(),
        );
      },
    );
  }
}