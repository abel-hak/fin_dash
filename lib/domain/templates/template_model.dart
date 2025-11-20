class SmsTemplate {
  final String id;
  final String sender;
  final String locale;
  final Map<String, String> patterns;
  final Map<String, dynamic> post;

  SmsTemplate({
    required this.id,
    required this.sender,
    required this.locale,
    required this.patterns,
    required this.post,
  });

  factory SmsTemplate.fromJson(Map<String, dynamic> json) {
    return SmsTemplate(
      id: json['id'],
      sender: json['sender'],
      locale: json['locale'] ?? 'en',
      patterns: Map<String, String>.from(json['patterns']),
      post: Map<String, dynamic>.from(json['post']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'locale': locale,
      'patterns': patterns,
      'post': post,
    };
  }
}

class TemplateRegistry {
  final List<SmsTemplate> templates;

  TemplateRegistry({required this.templates});

  factory TemplateRegistry.fromJson(List<dynamic> json) {
    return TemplateRegistry(
      templates: json.map((e) => SmsTemplate.fromJson(e)).toList(),
    );
  }

  List<SmsTemplate> getTemplatesForSender(String sender) {
    return templates.where((template) => 
      template.sender.toLowerCase() == sender.toLowerCase()
    ).toList();
  }

  List<String> getAllSenders() {
    return templates.map((template) => template.sender).toSet().toList();
  }
}
