# Allowance App

A simple, elegant Flutter app for tracking personal allowances and spending. Perfect for managing weekly or monthly allowance budgets with automatic allowance distribution.

## Features

### 🏦 Balance Management
- **Real-time balance tracking** - See your current available money at a glance
- **Automatic allowance distribution** - Receive your allowance automatically on your chosen day
- **Spending tracking** - Monitor how much you've spent since your last allowance

### 💰 Flexible Allowance Settings
- **Weekly or Monthly** allowance frequency
- **Custom allowance day** - Choose any day of the week or day of the month
- **Easy amount conversion** - Automatically converts between weekly and monthly amounts
- **Balance adjustments** - Manually adjust your current balance when needed

### 📱 Transaction Management
- **Quick transaction entry** - Add purchases with description, amount, and date
- **Transaction history** - View all your spending in chronological order
- **Swipe to delete** - Remove transactions with undo functionality
- **Date picker** - Backdate transactions if needed

### 🎨 Beautiful Design
- **Dark theme** with golden yellow accents
- **Clean, card-based interface**
- **Intuitive navigation**
- **Responsive design**

## Screenshots

*Add screenshots of your app here*

## Getting Started

### Prerequisites
- Flutter SDK (>=2.17.0 <3.0.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/allowance_app.git
   cd allowance_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## How It Works

### Automatic Allowance Distribution
The app automatically adds your allowance to your balance when you open it on your designated allowance day. No background processing required - it's checked every time you launch the app or return from settings.

### Balance Calculation
Your current balance is calculated as:
```
Current Balance = Last Set Balance - Spending Since Last Update
```

### Weekly vs Monthly
- Choose weekly or monthly allowance frequency
- Amounts are automatically converted using 4.33 weeks per month
- Settings remember your preference and allowance day

## Dependencies

- **hive & hive_flutter** - Local database storage
- **intl** - Date formatting
- **flutter_slidable** - Swipe-to-delete functionality
- **path_provider** - File system access

## Project Structure

```
lib/
├── main.dart                 # App entry point and theme
├── models/
│   ├── settings.dart         # Settings data model
│   ├── settings.g.dart       # Generated Hive adapter
│   ├── transaction.dart      # Transaction data model
│   └── transaction.g.dart    # Generated Hive adapter
├── screens/
│   ├── dashboard.dart        # Main balance and transaction view
│   ├── add_transaction.dart  # Add new transaction form
│   └── settings_screen.dart  # Allowance and balance settings
└── services/
    └── hive_service.dart     # Database service layer
```

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Customization

### Theme Colors
The app uses a dark theme with golden yellow accents. To customize colors, edit the `ColorScheme` in `main.dart`:

```dart
colorScheme: const ColorScheme.dark(
  primary: Color(0xFFFFD700), // Golden yellow
  secondary: Color(0xFFFFD700),
  surface: Color(0xFF1C1C1E), // Dark card color
  // ... other colors
),
```

### Default Settings
Default allowance settings can be modified in `models/settings.dart`:

```dart
static Settings defaultSettings() {
  return Settings(
    monthlyAllowance: 150.0,  // Default monthly allowance
    currentBalance: 150.0,    // Starting balance
    allowanceFrequency: 'monthly',
    allowanceDay: 1,          // 1st of month
  );
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter and Dart
- Uses Hive for fast, local data storage
- Inspired by the need for simple, effective allowance tracking

---

**Note**: This app stores all data locally on your device. No data is sent to external servers, ensuring your financial information stays private.