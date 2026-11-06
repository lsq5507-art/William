/// Local custom companion character (LP-P-17 / role-gen-web-v0.17).
/// Not a marketplace listing.
class CustomCharacter {
  final String id;
  final String name;
  final String blurb;
  final String? species;
  final String? tone;
  final String createdAtIso;

  const CustomCharacter({
    required this.id,
    required this.name,
    required this.blurb,
    this.species,
    this.tone,
    required this.createdAtIso,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'blurb': blurb,
        'species': species,
        'tone': tone,
        'createdAtIso': createdAtIso,
      };

  factory CustomCharacter.fromJson(Map<String, dynamic> j) => CustomCharacter(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        blurb: j['blurb'] as String? ?? '',
        species: j['species'] as String?,
        tone: j['tone'] as String?,
        createdAtIso: j['createdAtIso'] as String? ?? '',
      );
}
