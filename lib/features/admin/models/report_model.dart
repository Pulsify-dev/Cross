class Report {
  final String entityType; // 'Track', 'Album', or 'User'
  final String entityId;
  final String reason;
  final String? description;

  Report({
    required this.entityType,
    required this.entityId,
    required this.reason,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'entity_type': entityType,
    'entity_id': entityId,
    'reason': reason,
    'description': description,
  };
}