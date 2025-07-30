import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final transactionsBox = HiveService.getTransactionsBox();
  final settingsBox = HiveService.getSettingsBox();

  @override
  void initState() {
    super.initState();
    // Check for allowance when dashboard loads
    _checkAndAddAllowance();
  }

  // Check if allowance should be added and add it
  Future<void> _checkAndAddAllowance() async {
    final settings = HiveService.getSettings();
    if (settings.shouldAddAllowance()) {
      final newBalance = settings.currentBalance + settings.displayAllowance;
      final updatedSettings = Settings(
        monthlyAllowance: settings.monthlyAllowance,
        currentBalance: newBalance,
        lastBalanceUpdate: settings.lastBalanceUpdate,
        allowanceFrequency: settings.allowanceFrequency,
        allowanceDay: settings.allowanceDay,
        lastAllowanceDate: DateTime.now(),
      );

      await HiveService.updateSettings(updatedSettings);

      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Allowance added! +\$${settings.displayAllowance.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the UI
      }
    }
  }

  // Calculate spent amount since last balance update
  double _getSpentSinceLastUpdate(List<TransactionEntry> transactions, Settings settings) {
    return transactions
        .where((entry) => entry.date.isAfter(settings.lastBalanceUpdate))
        .fold<double>(0.0, (sum, entry) => sum + entry.amount);
  }

  double _getCurrentBalance(List<TransactionEntry> transactions, Settings settings) {
    final spentSinceUpdate = _getSpentSinceLastUpdate(transactions, settings);
    return settings.currentBalance - spentSinceUpdate;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // Check for allowance and refresh after returning from settings
              await _checkAndAddAllowance();
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: transactionsBox.listenable(),
          builder: (context, Box<TransactionEntry> currentBox, _) {
            final allTransactions = currentBox.values.toList();
            final settings = HiveService.getSettings();
            final currentBalance = _getCurrentBalance(allTransactions, settings);
            final spentSinceUpdate = _getSpentSinceLastUpdate(allTransactions, settings);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Spent Since Last Update',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${spentSinceUpdate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${settings.frequencyText} Allowance',
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${settings.displayAllowance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Next Allowance',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              settings.allowanceDayName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/add');
                      await _checkAndAddAllowance(); // Check for allowance after adding transaction
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Transaction'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final items = allTransactions.reversed.toList();
                      if (items.isEmpty) {
                        return const Center(child: Text("No transactions yet. Add your first one!"));
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final transaction = items[i];
                          final isAfterLastUpdate = transaction.date.isAfter(settings.lastBalanceUpdate);

                          return Slidable(
                            key: ValueKey(transaction.key),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    final deletedTransaction = transaction;
                                    final deletedKey = transaction.key;
                                    transaction.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Transaction deleted.'),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          onPressed: () {
                                            HiveService.getTransactionsBox().put(deletedKey, deletedTransaction);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                              title: Text(
                                transaction.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('MMMM dd, yyyy').format(transaction.date),
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                '\$${transaction.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onLongPress: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Long press detected for edit (not implemented yet)')),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}