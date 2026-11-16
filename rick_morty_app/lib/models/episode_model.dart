class Episode {
  final int id;
  final String name;
  final String airDate;
  final String episode;
  final List<String> characters;

  const Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episode,
    required this.characters,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      airDate: json['air_date'] as String? ?? '',
      episode: json['episode'] as String? ?? '',
      characters: json['characters'] != null
          ? List<String>.from(json['characters'])
          : [],
    );
  }
}
