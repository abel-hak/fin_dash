class Budget {
  final String id;
  final String name;
  final String category;
  final double limit;
  final double spent;
  final String period; // 'monthly', 'weekly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Budget({
    required this.id,
    required this.name,
    required this.category,
    required this.limit,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  double get remaining => limit - spent;
  
  double get percentage => limit > 0 ? (spent / limit * 100).clamp(0, 100) : 0;
  
  int get percentageInt => percentage.toInt();
  
  bool get isOverBudget => spent > limit;
  
  bool get isNearLimit => percentage >= 80 && !isOverBudget;
  
  String get status {
    if (isOverBudget) return 'Over Budget';
    if (isNearLimit) return 'Near Limit';
    return 'On Track';
  }
  
  int get daysLeft {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }
  
  double get dailyAverage {
    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays + 1;
    return daysPassed > 0 ? spent / daysPassed : 0;
  }
  
  double get projectedTotal {
    final totalDays = endDate.difference(startDate).inDays + 1;
    return dailyAverage * totalDays;
  }

  factory Budget.monthly({
    required String name,
    required String category,
    required double limit,
    required double spent,
  }) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    
    return Budget(
      id: '${category.toLowerCase()}_${now.year}_${now.month}',
      name: name,
      category: category,
      limit: limit,
      spent: spent,
      period: 'monthly',
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'limit_amount': limit,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, double spent) {
    return Budget(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      limit: map['limit_amount'],
      spent: spent,
      period: map['period'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: map['is_active'] == 1,
    );
  }

  static String getCategoryFromMerchant(String merchant, {String? reason}) {
    // Priority 1: Check reason field first (most accurate)
    if (reason != null && reason.isNotEmpty) {
      final lowerReason = reason.toLowerCase();
      
      // Transfer category
      if (lowerReason.contains('transfer') || 
          lowerReason.contains('fund transfer') ||
          lowerReason.contains('send money')) {
        return 'Transfer';
      }
      
      // Utilities (Internet, Bills, etc.)
      if (lowerReason.contains('internet') || 
          lowerReason.contains('data') ||
          lowerReason.contains('package') ||
          lowerReason.contains('electric') || 
          lowerReason.contains('water') || 
          lowerReason.contains('utility') ||
          lowerReason.contains('bill payment')) {
        return 'Utilities';
      }
      
      // Food & Dining
      if (lowerReason.contains('food') || 
          lowerReason.contains('restaurant') ||
          lowerReason.contains('lunch') ||
          lowerReason.contains('dinner') ||
          lowerReason.contains('cafe') ||
          lowerReason.contains('coffee') ||
          lowerReason.contains('grocery')) {
        return 'Food & Dining';
      }
      
      // Transportation
      if (lowerReason.contains('ride') || 
          lowerReason.contains('taxi') || 
          lowerReason.contains('transport') ||
          lowerReason.contains('fuel') ||
          lowerReason.contains('gas') ||
          lowerReason.contains('uber') ||
          lowerReason.contains('bus')) {
        return 'Transportation';
      }
      
      // Shopping
      if (lowerReason.contains('shop') || 
          lowerReason.contains('purchase') || 
          lowerReason.contains('store') || 
          lowerReason.contains('mall') ||
          lowerReason.contains('clothing') ||
          lowerReason.contains('buy')) {
        return 'Shopping';
      }
      
      // Entertainment
      if (lowerReason.contains('movie') || 
          lowerReason.contains('cinema') || 
          lowerReason.contains('entertainment') ||
          lowerReason.contains('game') ||
          lowerReason.contains('music') ||
          lowerReason.contains('concert')) {
        return 'Entertainment';
      }
      
      // Healthcare
      if (lowerReason.contains('health') || 
          lowerReason.contains('hospital') || 
          lowerReason.contains('pharmacy') ||
          lowerReason.contains('doctor') ||
          lowerReason.contains('medical') ||
          lowerReason.contains('medicine')) {
        return 'Healthcare';
      }
    }
    
    // Priority 2: Fallback to merchant name
    final lowerMerchant = merchant.toLowerCase();
    
    if (lowerMerchant.contains('lunch') || 
        lowerMerchant.contains('food') || 
        lowerMerchant.contains('restaurant') ||
        lowerMerchant.contains('cafe') ||
        lowerMerchant.contains('grocery')) {
      return 'Food & Dining';
    }
    
    if (lowerMerchant.contains('ride') || 
        lowerMerchant.contains('taxi') || 
        lowerMerchant.contains('transport') ||
        lowerMerchant.contains('fuel') ||
        lowerMerchant.contains('gas')) {
      return 'Transportation';
    }
    
    if (lowerMerchant.contains('movie') || 
        lowerMerchant.contains('cinema') || 
        lowerMerchant.contains('entertainment') ||
        lowerMerchant.contains('game') ||
        lowerMerchant.contains('music')) {
      return 'Entertainment';
    }
    
    if (lowerMerchant.contains('shop') || 
        lowerMerchant.contains('store') || 
        lowerMerchant.contains('mall') ||
        lowerMerchant.contains('clothing')) {
      return 'Shopping';
    }
    
    if (lowerMerchant.contains('electric') || 
        lowerMerchant.contains('water') || 
        lowerMerchant.contains('utility') ||
        lowerMerchant.contains('bill')) {
      return 'Utilities';
    }
    
    if (lowerMerchant.contains('health') || 
        lowerMerchant.contains('hospital') || 
        lowerMerchant.contains('pharmacy') ||
        lowerMerchant.contains('doctor')) {
      return 'Healthcare';
    }
    
    return 'Other';
  }
}
