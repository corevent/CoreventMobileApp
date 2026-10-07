String membershipLabel(DateTime? createdAt, DateTime now) {
  if (createdAt == null) return 'Membro Corevent';
  final local = createdAt.toLocal();
  final joined = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(joined).inDays;
  if (days < 0) return 'Membro Corevent';
  if (days == 0) return 'Membro desde hoje';
  if (days == 1) return 'Membro há 1 dia';
  return 'Membro há $days dias';
}
