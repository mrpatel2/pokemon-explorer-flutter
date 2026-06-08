class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final String types; // separated by comma

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  // Extract numeric ID from PokeAPI URL like "https://pokeapi.co/api/v2/pokemon/25/"
  static int extractId(String url) {
    final parts = url.split('/');
    return int.parse(parts[parts.length - 2]);
  }

  // Parse from PokeAPI detail endpoint
  factory Pokemon.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final typesList = (json['types'] as List)
        .map((t) => t['type']['name'] as String)
        .toList();

    return Pokemon(
      id: id,
      name: json['name'] as String,
      imageUrl: (json['sprites']['front_default'] as String?) ??
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
      types: typesList.join(','),
    );
  }

  // Convert to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'types': types,
    };
  }

  // Build a Pokemon from a SQLite row
  factory Pokemon.fromMap(Map<String, dynamic> map) {
    return Pokemon(
      id: map['id'] as int,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String,
      types: map['types'] as String,
    );
  }

  // splits types string back into a list
  List<String> get typeList => types.isEmpty ? [] : types.split(',');
}