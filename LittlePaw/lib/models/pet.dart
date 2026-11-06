/// Pet model — 现实 / 想念中 / 虚构
enum PetType { real, missed, fiction }

class Pet {
  final String id;
  final String name;
  final String species;
  final PetType type;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
        id: j['id'] as String,
        name: j['name'] as String,
        species: j['species'] as String? ?? 'pet',
        type: PetType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => PetType.fiction,
        ),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    PetType? type,
    DateTime? createdAt,
  }) =>
      Pet(
        id: id ?? this.id,
        name: name ?? this.name,
        species: species ?? this.species,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );
}

