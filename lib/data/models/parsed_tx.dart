enum TransactionStatus { pending, approved, synced, ignored }

class ParsedTransaction {
  final String id;
  final String sender;
  final double amount;
  final String currency;
  final String occurredAt;
  final String merchant;
  final String? accountAlias;
  final double? balance;
  final String channel;
  final double confidence;
  final String fingerprint;
  final TransactionStatus status;
  final String createdAt;
  final String? transactionId;
  final String? timestamp;
  final String? recipient;
  final String? receiptLink;
  final bool hasReceipt;
  final String? dataSource; // 'sms', 'receipt_html', 'receipt_pdf_ai'
  final String? payerAccount;
  final String? merchantAccount;
  final double? serviceCharge;
  final double? vat;
  final double? totalAmount;
  final String? paymentMethod;
  final String? branch;
  final String? reason; // Payment purpose/description

  ParsedTransaction({
    required this.id,
    required this.sender,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.merchant,
    this.accountAlias,
    this.balance,
    required this.channel,
    required this.confidence,
    required this.fingerprint,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.timestamp,
    this.recipient,
    this.receiptLink,
    this.hasReceipt = false,
    this.dataSource,
    this.payerAccount,
    this.merchantAccount,
    this.serviceCharge,
    this.vat,
    this.totalAmount,
    this.paymentMethod,
    this.branch,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'amount': amount,
      'currency': currency,
      'occurred_at': occurredAt,
      'merchant': merchant,
      'account_alias': accountAlias,
      'balance': balance,
      'channel': channel,
      'confidence': confidence,
      'fingerprint': fingerprint,
      'status': status.toString().split('.').last,
      'created_at': createdAt,
      'transaction_id': transactionId,
      'timestamp': timestamp,
      'recipient': recipient,
      'receipt_link': receiptLink,
      'has_receipt': hasReceipt ? 1 : 0,
      'data_source': dataSource,
      'payer_account': payerAccount,
      'merchant_account': merchantAccount,
      'service_charge': serviceCharge,
      'vat': vat,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'branch': branch,
      'reason': reason,
    };
  }

  factory ParsedTransaction.fromMap(Map<String, dynamic> map) {
    return ParsedTransaction(
      id: map['id'] as String,
      sender: map['sender'] as String? ?? '',
      amount: _coerceDouble(map['amount']),
      currency: map['currency'] as String? ?? '',
      occurredAt: map['occurred_at'] as String? ?? '',
      merchant: map['merchant'] as String? ?? '',
      accountAlias: map['account_alias'] as String?,
      balance: _coerceNullableDouble(map['balance']),
      channel: map['channel'] as String? ?? '',
      confidence: _coerceDouble(map['confidence']).clamp(0.0, 1.0),
      fingerprint: map['fingerprint'] as String? ?? '',
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      createdAt: map['created_at'] as String? ?? '',
      transactionId: map['transaction_id'] as String?,
      timestamp: map['timestamp'] as String?,
      recipient: map['recipient'] as String?,
      receiptLink: map['receipt_link'] as String?,
      hasReceipt: map['has_receipt'] == 1,
      dataSource: map['data_source'] as String?,
      payerAccount: map['payer_account'] as String?,
      merchantAccount: map['merchant_account'] as String?,
      serviceCharge: _coerceNullableDouble(map['service_charge']),
      vat: _coerceNullableDouble(map['vat']),
      totalAmount: _coerceNullableDouble(map['total_amount']),
      paymentMethod: map['payment_method'] as String?,
      branch: map['branch'] as String?,
      reason: map['reason'] as String?,
    );
  }

  static double _coerceDouble(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0.0);

  static double? _coerceNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  ParsedTransaction copyWith({
    String? id,
    String? sender,
    double? amount,
    String? currency,
    String? occurredAt,
    String? merchant,
    String? accountAlias,
    double? balance,
    String? channel,
    double? confidence,
    String? fingerprint,
    TransactionStatus? status,
    String? createdAt,
    String? transactionId,
    String? timestamp,
    String? recipient,
    String? receiptLink,
    bool? hasReceipt,
    String? dataSource,
    String? payerAccount,
    String? merchantAccount,
    double? serviceCharge,
    double? vat,
    double? totalAmount,
    String? paymentMethod,
    String? branch,
    String? reason,
  }) {
    return ParsedTransaction(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      occurredAt: occurredAt ?? this.occurredAt,
      merchant: merchant ?? this.merchant,
      accountAlias: accountAlias ?? this.accountAlias,
      balance: balance ?? this.balance,
      channel: channel ?? this.channel,
      confidence: confidence ?? this.confidence,
      fingerprint: fingerprint ?? this.fingerprint,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      timestamp: timestamp ?? this.timestamp,
      recipient: recipient ?? this.recipient,
      receiptLink: receiptLink ?? this.receiptLink,
      hasReceipt: hasReceipt ?? this.hasReceipt,
      dataSource: dataSource ?? this.dataSource,
      payerAccount: payerAccount ?? this.payerAccount,
      merchantAccount: merchantAccount ?? this.merchantAccount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      branch: branch ?? this.branch,
      reason: reason ?? this.reason,
    );
  }

  // For sending to backend
  Map<String, dynamic> toBackendJson() {
    return {
      'occurred_at': occurredAt,
      'amount': amount,
      'currency': currency,
      'merchant': merchant,
      'channel': channel,
      'account_alias': accountAlias,
      'balance': balance,
      'confidence': confidence,
      'fingerprint': fingerprint,
      'transaction_id': transactionId,
      'timestamp': timestamp,
      'recipient': recipient,
    };
  }
}
