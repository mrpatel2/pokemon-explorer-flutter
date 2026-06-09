import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();
  final PreferencesService _prefs = PreferencesService();
  final TextEditingController _searchController = TextEditingController();

  List<Pokemon> _pokemonList = [];
  Set<int> _favoritedIds = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasLoaded = false; // tracks if done at least one fetch

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // restores last search from preferences
  Future<void> _initScreen() async {
    await _loadFavoritedIds();
    final lastSearch = await _prefs.getLastSearch();
    if (lastSearch.isNotEmpty) {
      _searchController.text = lastSearch;
      await _searchPokemon(lastSearch);
    } else {
      await _fetchDefaultList();
    }
  }

  // Load the set of favorited IDs from SQLite so hearts show correctly
  Future<void> _loadFavoritedIds() async {
    final favorites = await _db.getAllFavorites();
    if (mounted) {
      setState(() {
        _favoritedIds = favorites.map((p) => p.id).toSet();
      });
    }
  }

  // Fetch the default browse list which is first 20 pokemon
  Future<void> _fetchDefaultList() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final listItems = await _api.fetchPokemonList();
      final pokemons = listItems.map((item) {
        final id = Pokemon.extractId(item['url']!);
        return Pokemon(
          id: id,
          name: item['name']!,
          imageUrl:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
          types: '',
        );
      }).toList();

      setState(() {
        _pokemonList = pokemons;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Search for a specific pokemon by exact name or number
  Future<void> _searchPokemon(String query) async {
    if (query.trim().isEmpty) {
      await _prefs.saveLastSearch('');
      await _fetchDefaultList();
      return;
    }

    await _prefs.saveLastSearch(query.trim());

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasLoaded = true;
    });

    try {
      final pokemon = await _api.fetchPokemonDetail(query.trim());
      setState(() {
        _pokemonList = [pokemon];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Clear the search bar and go back to default list
  void _clearSearch() {
    _searchController.clear();
    _prefs.saveLastSearch('');
    _fetchDefaultList();
  }

  // Save or unsave a pokemon when the heart icon is tapped
  Future<void> _toggleFavorite(Pokemon pokemon) async {
    final isFav = _favoritedIds.contains(pokemon.id);

    if (isFav) {
      // Remove from favorites
      await _db.removeFavorite(pokemon.id);
      setState(() => _favoritedIds.remove(pokemon.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_capitalize(pokemon.name)} removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // If types are missing then fetch full details before saving
      Pokemon toSave = pokemon;
      if (pokemon.types.isEmpty) {
        try {
          toSave = await _api.fetchPokemonDetail(pokemon.name);
        } catch (_) {
          toSave = pokemon;
        }
      }
      await _db.addFavorite(toSave);
      setState(() => _favoritedIds.add(pokemon.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_capitalize(pokemon.name)} saved to favorites! ❤️',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  //Build Methods

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Explorer'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type exact name (e.g. pikachu) or number (e.g. 25)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                  tooltip: 'Clear search',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchPokemon,
            ),
          ),

          // Main content area
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 1. Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Loading Pokémon...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 2. Error state
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.toLowerCase().contains('not found')
                    ? 'Pokémon not found.\nCheck the spelling or try a different name.'
                    : 'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    _searchPokemon(_searchController.text);
                  } else {
                    _fetchDefaultList();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty state
    if (!_hasLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.catching_pokemon, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for a Pokémon to get started!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 4. Empty results state
    if (_pokemonList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Pokémon found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 5. Success — show the list with pull to refresh
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: () => _searchController.text.trim().isNotEmpty
          ? _searchPokemon(_searchController.text)
          : _fetchDefaultList(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _pokemonList.length,
        itemBuilder: (context, index) {
          final pokemon = _pokemonList[index];
          return _buildPokemonCard(pokemon);
        },
      ),
    );
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    final isFavorite = _favoritedIds.contains(pokemon.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Pokemon sprite
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pokemon.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // name, number, types
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${pokemon.id}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Text(
                    _capitalize(pokemon.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (pokemon.types.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: pokemon.typeList
                            .map(
                              (type) => Chip(
                                label: Text(
                                  _capitalize(type),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: _typeColor(type),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            // Heart or favorite button
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
                size: 28,
              ),
              onPressed: () => _toggleFavorite(pokemon),
              tooltip: isFavorite
                  ? 'Remove from favorites'
                  : 'Save to favorites',
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _typeColor(String type) {
    const colors = {
      'fire': Color(0xFFFF4422),
      'water': Color(0xFF3399FF),
      'grass': Color(0xFF77CC55),
      'electric': Color(0xFFFFCC33),
      'psychic': Color(0xFFFF5599),
      'ice': Color(0xFF66CCFF),
      'dragon': Color(0xFF7766EE),
      'dark': Color(0xFF775544),
      'fairy': Color(0xFFEE99EE),
      'fighting': Color(0xFFBB5544),
      'poison': Color(0xFFAA5599),
      'ground': Color(0xFFDDBB55),
      'flying': Color(0xFF8899FF),
      'bug': Color(0xFFAABB22),
      'rock': Color(0xFFBBAA66),
      'ghost': Color(0xFF6666BB),
      'steel': Color(0xFFAAAABB),
      'normal': Color(0xFFAAAA99),
    };
    return colors[type] ?? Colors.grey;
  }
}
