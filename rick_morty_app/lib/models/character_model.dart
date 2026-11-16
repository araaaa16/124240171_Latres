class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String gender;
  final String image;
  final String originName;
  final String locationName;
  final List<String> episode;

  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.image,
    required this.originName,
    required this.locationName,
    required this.episode,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      species: json['species'] as String? ?? 'unknown',
      gender: json['gender'] as String? ?? 'unknown',
      image: json['image'] as String? ?? '',
      originName: json['origin'] != null
          ? (json['origin']['name'] as String? ?? 'unknown')
          : 'unknown',
      locationName: json['location'] != null
          ? (json['location']['name'] as String? ?? 'unknown')
          : 'unknown',
      episode: json['episode'] != null
          ? List<String>.from(json['episode'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'gender': gender,
      'image': image,
      'origin': {'name': originName},
      'location': {'name': locationName},
      'episode': episode,
    };
  }
}
