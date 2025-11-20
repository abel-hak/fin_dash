class Account {
  final String id;
  final String name;
  final String type; // 'bank', 'mobile_money', 'cash'
  final String sender; // SMS sender identifier
  final double balance;
  final int transactionCount;
  final DateTime lastSynced;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.sender,
    required this.balance,
    required this.transactionCount,
    required this.lastSynced,
  });

  factory Account.fromTransactions({
    required String sender,
    required double balance,
    required int transactionCount,
    required DateTime lastSynced,
  }) {
    final accountInfo = _parseAccountInfo(sender);
    
    return Account(
      id: sender.toLowerCase().replaceAll(' ', '_'),
      name: accountInfo['name']!,
      type: accountInfo['type']!,
      sender: sender,
      balance: balance,
      transactionCount: transactionCount,
      lastSynced: lastSynced,
    );
  }

  static Map<String, String> _parseAccountInfo(String sender) {
    final lowerSender = sender.toLowerCase();
    
    // Commercial Bank of Ethiopia
    if (lowerSender.contains('cbe')) {
      return {
        'name': 'Commercial Bank of Ethiopia',
        'type': 'bank',
      };
    }
    
    // Telebirr
    if (lowerSender.contains('telebirr')) {
      return {
        'name': 'Telebirr Mobile Money',
        'type': 'mobile_money',
      };
    }
    
    // Awash Bank
    if (lowerSender.contains('awash')) {
      return {
        'name': 'Awash Bank',
        'type': 'bank',
      };
    }
    
    // Bank of Abyssinia
    if (lowerSender.contains('abyssinia')) {
      return {
        'name': 'Bank of Abyssinia',
        'type': 'bank',
      };
    }
    
    // M-PESA
    if (lowerSender.contains('mpesa') || lowerSender.contains('m-pesa')) {
      return {
        'name': 'M-PESA',
        'type': 'mobile_money',
      };
    }
    
    // Generic bank
    if (lowerSender.contains('bank')) {
      return {
        'name': sender,
        'type': 'bank',
      };
    }
    
    // Default
    return {
      'name': sender,
      'type': 'other',
    };
  }

  String get displayType {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      default:
        return 'Other';
    }
  }

  String get iconName {
    switch (type) {
      case 'bank':
        return 'account_balance';
      case 'mobile_money':
        return 'phone_android';
      case 'cash':
        return 'account_balance_wallet';
      default:
        return 'account_circle';
    }
  }
}
