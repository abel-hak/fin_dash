enum TransactionStatus { pending, approved, synced }

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
      id: map['id'],
      sender: map['sender'],
      amount: map['amount'],
      currency: map['currency'],
      occurredAt: map['occurred_at'],
      merchant: map['merchant'],
      accountAlias: map['account_alias'],
      balance: map['balance'],
      channel: map['channel'],
      confidence: map['confidence'],
      fingerprint: map['fingerprint'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      createdAt: map['created_at'],
      transactionId: map['transaction_id'],
      timestamp: map['timestamp'],
      recipient: map['recipient'],
      receiptLink: map['receipt_link'],
      hasReceipt: map['has_receipt'] == 1,
      dataSource: map['data_source'],
      payerAccount: map['payer_account'],
      merchantAccount: map['merchant_account'],
      serviceCharge: map['service_charge'],
      vat: map['vat'],
      totalAmount: map['total_amount'],
      paymentMethod: map['payment_method'],
      branch: map['branch'],
      reason: map['reason'],
    );
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
