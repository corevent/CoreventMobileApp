class EventCategory {
  const EventCategory(this.value, this.label);

  final String value;
  final String label;
}

abstract final class EventCatalog {
  static const categories = <EventCategory>[
    EventCategory('music', 'Música'),
    EventCategory('tech', 'Tecnologia'),
    EventCategory('education', 'Educação'),
    EventCategory('sports', 'Esportes'),
    EventCategory('business', 'Negócios'),
    EventCategory('art_culture', 'Arte e cultura'),
    EventCategory('gastronomy', 'Gastronomia'),
    EventCategory('health_wellness', 'Saúde e bem-estar'),
    EventCategory('family_kids', 'Família e crianças'),
    EventCategory('religious_spiritual', 'Religioso e espiritual'),
    EventCategory('games', 'Jogos'),
    EventCategory('community_social', 'Comunidade'),
    EventCategory('fashion_beauty', 'Moda e beleza'),
    EventCategory('other', 'Outros'),
  ];

  static String categoryLabel(String value) {
    for (final category in categories) {
      if (category.value == value) return category.label;
    }
    return value;
  }

  static String locationTypeLabel(String? value) => switch (value) {
    'online' => 'Online',
    'hybrid' => 'Híbrido',
    _ => 'Presencial',
  };
}
