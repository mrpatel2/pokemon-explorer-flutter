import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class ApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  // Fetches a list of 20 pokemon (names + detail URLs only)
  Future<List<Map<String, String>>> fetchPokemonList({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      return results
          .map((item) => {
                'name': item['name'] as String,
                'url': item['url'] as String,
              })
          .toList();
    } else {
      throw Exception('Failed to load Pokémon list. Status: ${response.statusCode}');
    }
  }

  // Fetches full details for one pokemon by exact name or ID number
  Future<Pokemon> fetchPokemonDetail(String nameOrId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pokemon/${nameOrId.toLowerCase().trim()}'),
    );

    if (response.statusCode == 200) {
      return Pokemon.fromApiJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Pokémon "$nameOrId" not found');
    } else {
      throw Exception('Failed to fetch Pokémon. Status: ${response.statusCode}');
    }
  }
}