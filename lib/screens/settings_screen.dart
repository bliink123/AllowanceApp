import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _allowanceController;
  late TextEditingController _currentBalanceController;
  late Settings _currentSettings;
  late String _selectedFrequency;
  late int _selectedAllowanceDay;

  @override
  void initState() {
    super.initState();
    _currentSettings = HiveService.getSettings();
    _selectedFrequency = _currentSettings.allowanceFrequency;
    _selectedAllowanceDay = _currentSettings.allowanceDay;

    // Display the allowance amount based on current frequency
    final displayAmount = _currentSettings.allowanceFrequency == 'weekly'
        ? _currentSettings.weeklyAllowance
        : _currentSettings.monthlyAllowance;

    _allowanceController = TextEditingController(
        text: displayAmount.toStringAsFixed(2)
    );
    _currentBalanceController = TextEditingController(
        text: _currentSettings.currentBalance.toStringAsFixed(2)
    );
  }

  @override
  void dispose() {
    _allowanceController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String? newFrequency) {
    if (newFrequency != null && newFrequency != _selectedFrequency) {
      setState(() {
        final currentAmount = double.tryParse(_allowanceController.text) ?? 0;

        // Convert the amount when switching frequencies
        double newAmount;
        if (_selectedFrequency == 'monthly' && newFrequency == 'weekly') {
          // Converting from monthly to weekly
          newAmount = currentAmount / 4.33;
          _selectedAllowanceDay = 4; // Default to Thursday for weekly
        } else if (_selectedFrequency == 'weekly' && newFrequency == 'monthly') {
          // Converting from weekly to monthly
          newAmount = currentAmount * 4.33;
          _selectedAllowanceDay = 1; // Default to 1st for monthly
        } else {
          newAmount = currentAmount;
        }

        _selectedFrequency = newFrequency;
        _allowanceController.text = newAmount.toStringAsFixed(2);
      });
    }
  }

  List<DropdownMenuItem<int>> _getDayOptions() {
    if (_selectedFrequency == 'weekly') {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key + 1,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        );
      }).toList();
    } else {
      // Monthly: 1st through 28th
      return List.generate(28, (index) {
        final day = index + 1;
        final suffix = _getOrdinalSuffix(day);
        return DropdownMenuItem<int>(
          value: day,
          child: Text('$day$suffix', style: const TextStyle(color: Colors.white)),
        );
      });
    }
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final enteredAmount = double.parse(_allowanceController.text);
      final newCurrentBalance = double.parse(_currentBalanceController.text);

      // Convert to monthly amount for storage (we always store as monthly internally)
      final monthlyAmount = _selectedFrequency == 'weekly'
          ? enteredAmount * 4.33
          : enteredAmount;

      final updatedSettings = Settings(
        monthlyAllowance: monthlyAmount,
        currentBalance: newCurrentBalance,
        lastBalanceUpdate: DateTime.now(),
        allowanceFrequency: _selectedFrequency,
        allowanceDay: _selectedAllowanceDay,
        lastAllowanceDate: _currentSettings.lastAllowanceDate, // Preserve existing allowance date
      );

      await HiveService.updateSettings(updatedSettings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );

      Navigator.pop(context);
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allowance Settings',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Allowance Day selector
                      Text(
                        'Allowance Day',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedAllowanceDay,
                            hint: Text(
                              _selectedFrequency == 'weekly' ? 'Select day of week' : 'Select day of month',
                              style: const TextStyle(color: Color(0xFF8E8E93)),
                            ),
                            dropdownColor: const Color(0xFF1C1C1E),
                            style: const TextStyle(color: Colors.white),
                            items: _getDayOptions(),
                            onChanged: (int? newDay) {
                              if (newDay != null) {
                                setState(() {
                                  _selectedAllowanceDay = newDay;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Frequency selector
                      Text(
                        'Allowance Frequency',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Weekly', style: TextStyle(color: Colors.white)),
                                value: 'weekly',
                                groupValue: _selectedFrequency,
                                activeColor: Theme.of(context).colorScheme.secondary,
                                onChanged: _onFrequencyChanged,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Monthly', style: TextStyle(color: Colors.white)),
                                value: 'monthly',
                                groupValue: _selectedFrequency,
                                activeColor: Theme.of(context).colorScheme.secondary,
                                onChanged: _onFrequencyChanged,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _allowanceController,
                        decoration: InputDecoration(
                          labelText: '${_selectedFrequency == 'weekly' ? 'Weekly' : 'Monthly'} Allowance',
                          prefixText: '\$ ',
                          hintText: 'e.g., ${_selectedFrequency == 'weekly' ? '35.00' : '150.00'}',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validateAmount,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentBalanceController,
                        decoration: const InputDecoration(
                          labelText: 'Current Balance',
                          prefixText: '\$ ',
                          hintText: 'e.g., 75.50',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validateAmount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How This Works',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Allowance Frequency: Choose weekly or monthly payments\n'
                            '• Allowance Day: When you receive your allowance automatically\n'
                            '• Allowance Amount: The amount you receive each period\n'
                            '• Current Balance: Your actual available money right now\n'
                            '• The app will automatically add your allowance on the selected day',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}