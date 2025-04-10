
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const BudgetHomePage(),
    );
  }
}

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({super.key});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  double _balance = 0.0;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadTransactions();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getDouble('balance') ?? 0.0;
    });
  }

  Future<void> _saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', balance);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt('tx_count') ?? 0;
    List<Map<String, dynamic>> loaded = [];
    for (int i = 0; i < count; i++) {
      final item = prefs.getString('tx_${i}_item') ?? '';
      final amount = prefs.getDouble('tx_${i}_amount') ?? 0.0;
      final date = prefs.getString('tx_${i}_date') ?? '';
      final balance = prefs.getDouble('tx_${i}_balance') ?? 0.0;
      loaded.add({
        'item': item,
        'amount': amount,
        'date': date,
        'balance': balance,
      });
    }
    setState(() {
      _transactions = loaded;
    });
  }

  Future<void> _saveTransaction(String item, double amount, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('tx_count') ?? 0;
    final now = DateTime.now().toString();
    await prefs.setString('tx_${count}_item', item);
    await prefs.setDouble('tx_${count}_amount', amount);
    await prefs.setString('tx_${count}_date', now);
    await prefs.setDouble('tx_${count}_balance', balance);
    await prefs.setInt('tx_count', count + 1);
  }

  void _addTransaction() {
    final String item = _itemController.text;
    final double? amount = double.tryParse(_amountController.text);
    if (item.isEmpty || amount == null) return;

    setState(() {
      _balance -= amount;
      _transactions.insert(0, {
        'item': item,
        'amount': amount,
        'date': DateTime.now().toString(),
        'balance': _balance,
      });
      _saveBalance(_balance);
      _saveTransaction(item, amount, _balance);
      _itemController.clear();
      _amountController.clear();
    });
  }

  void _updateBalance(double newBalance) {
    setState(() {
      _balance = newBalance;
      _saveBalance(newBalance);
    });
  }

  void _showBalanceDialog() {
    final controller = TextEditingController(text: _balance.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Balance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter new balance'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newBalance = double.tryParse(controller.text);
              if (newBalance != null) {
                _updateBalance(newBalance);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Balance: ₹${_balance.toStringAsFixed(2)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showBalanceDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Add Expense'),
            ),
            const SizedBox(height: 20),
            const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (ctx, i) {
                  final tx = _transactions[i];
                  return ListTile(
                    title: Text(tx['item']),
                    subtitle: Text('₹${tx['amount']} on ${tx['date']}'),
                    trailing: Text('Bal: ₹${tx['balance'].toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
