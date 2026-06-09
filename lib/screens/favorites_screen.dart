import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _db = DatabaseService();
  final PreferencesService _prefs = PreferencesService();

  List<Pokemon> _favorites = [];
  bool _isLoading = true;
  String _sortOrder = 'id'; // 'id' or 'name' — saved in shared_preferences

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Load favorites from SQLite, applying saved sort order
  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final sortOrder = await _prefs.getSortOrder();
    final favorites = await _db.getAllFavorites();

    // Sort based on saved preference
    final sorted = List<Pokemon>.from(favorites);
    if (sortOrder == 'name') {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    } else {
      sorted.sort((a, b) => a.id.compareTo(b.id));
    }

    setState(() {
      _favorites = sorted;
      _sortOrder = sortOrder;
      _isLoading = false;
    });
  }

  // Toggle between sorting by ID and name, saves to shared_preferences
  Future<void> _toggleSort() async {
    final newSort = _sortOrder == 'id' ? 'name' : 'id';
    await _prefs.saveSortOrder(newSort);
    await _loadFavorites();
  }

  // Delete a single pokemon and show an Undo
  Future<void> _deleteFavorite(Pokemon pokemon) async {
    await _db.removeFavorite(pokemon.id);
    setState(() => _favorites.removeWhere((p) => p.id == pokemon.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_capitalize(pokemon.name)} removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _db.addFavorite(pokemon);
              await _loadFavorites();
            },
          ),
        ),
      );
    }
  }

  // Clear favorites after confirmation dialog
  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'This will permanently delete all saved Pokémon and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.clearAll();
      setState(() => _favorites.clear());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All favorites cleared')));
      }
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Build Methods

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites (${_favorites.length})'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Sort toggle button
          IconButton(
            icon: Icon(
              _sortOrder == 'id'
                  ? Icons.sort_by_alpha
                  : Icons.format_list_numbered,
            ),
            tooltip: _sortOrder == 'id' ? 'Sort A–Z' : 'Sort by Number',
            onPressed: _toggleSort,
          ),
          // Clear All button
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _favorites.isEmpty
          ? _buildEmptyState()
          : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No favorites yet!',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Go to Browse, search for a Pokémon,\nand tap ♥ to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final pokemon = _favorites[index];
          return _buildFavoriteCard(pokemon);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Pokemon pokemon) {
    return Dismissible(
      key: Key('fav_${pokemon.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteFavorite(pokemon),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Pokemon image
              Image.network(
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
              ),
              const SizedBox(width: 16),
              // Info
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
                      Text(
                        pokemon.typeList.map(_capitalize).join(' · '),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteFavorite(pokemon),
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
