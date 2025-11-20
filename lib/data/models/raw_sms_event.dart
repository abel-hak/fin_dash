class RawSmsEvent {
  final String id;
  final String sender;
  final String body;
  final int providerTs;
  final int receivedTs;
  final int handled;

  RawSmsEvent({
    required this.id,
    required this.sender,
    required this.body,
    required this.providerTs,
    required this.receivedTs,
    required this.handled,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'body': body,
      'provider_ts': providerTs,
      'received_ts': receivedTs,
      'handled': handled,
    };
  }

  factory RawSmsEvent.fromMap(Map<String, dynamic> map) {
    return RawSmsEvent(
      id: map['id'],
      sender: map['sender'],
      body: map['body'],
      providerTs: map['provider_ts'],
      receivedTs: map['received_ts'],
      handled: map['handled'],
    );
  }

  RawSmsEvent copyWith({
    String? id,
    String? sender,
    String? body,
    int? providerTs,
    int? receivedTs,
    int? handled,
  }) {
    return RawSmsEvent(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      providerTs: providerTs ?? this.providerTs,
      receivedTs: receivedTs ?? this.receivedTs,
      handled: handled ?? this.handled,
    );
  }
}
