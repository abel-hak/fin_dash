class Goal {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String iconName;
  final bool isActive;

  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.iconName,
    required this.isActive,
  });

  double get remaining => targetAmount - currentAmount;
  
  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
  
  int get percentageInt => percentage.toInt();
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  int get daysLeft {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return 0;
    return deadline.difference(now).inDays;
  }
  
  double get monthlyTarget {
    final now = DateTime.now();
    final monthsLeft = ((deadline.year - now.year) * 12 + deadline.month - now.month).clamp(1, 1000);
    return remaining / monthsLeft;
  }
  
  // Calculate suggested monthly contribution based on remaining amount and time
  double get suggestedMonthlyContribution {
    if (isCompleted) return 0;
    final now = DateTime.now();
    final monthsLeft = ((deadline.year - now.year) * 12 + deadline.month - now.month).clamp(1, 1000);
    return remaining / monthsLeft;
  }

  factory Goal.create({
    required String name,
    required String description,
    required double targetAmount,
    required DateTime deadline,
    String iconName = 'flag',
  }) {
    return Goal(
      id: '${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      iconName: iconName,
      isActive: true,
    );
  }

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? iconName,
    bool? isActive,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
    );
  }

  // Add contribution to goal
  Goal addContribution(double amount) {
    return copyWith(
      currentAmount: (currentAmount + amount).clamp(0, targetAmount),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'icon_name': iconName,
      'is_active': isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      targetAmount: map['target_amount'],
      currentAmount: map['current_amount'],
      deadline: DateTime.parse(map['deadline']),
      iconName: map['icon_name'],
      isActive: map['is_active'] == 1,
    );
  }
}
