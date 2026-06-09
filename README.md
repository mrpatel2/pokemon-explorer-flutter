# Pokemon Explorer

A Flutter app that fetches live Pokemon data from the PokeAPI and saves your favorites
locally using SQLite — so they survive app restarts.

## API Used

PokeAPI — https://pokeapi.co  
- List endpoint: 'https://pokeapi.co/api/v2/pokemon?limit=20'
- Detail endpoint: 'https://pokeapi.co/api/v2/pokemon/{name-or-id}'
- No API key required

## Storage Strategy

| Data | Storage | Why |
|---|---|---|
| Saved favorites (id, name, image, types) | SQLite via 'sqflite' | Structured data that needs to persist and be queryable |
| Last search query | 'shared_preferences' | Lightweight string, no complex structure needed |
| Sort order preference | 'shared_preferences' | Single key-value string setting |

## Data Format

Each saved favorite is a row in the 'favorites' SQLite table:

| Column | Type | Description |
|---|---|---|
| id | INTEGER (PK) | Pokemon's national number |
| name | TEXT | e.g. "pikachu" |
| imageUrl | TEXT | Sprite URL from PokeAPI |
| types | TEXT | Comma-separated, e.g. "electric" |
| savedAt | TEXT | ISO 8601 timestamp |

## How to Run

1. Clone this repo: 'git clone https://github.com/mrpatel2/pokemon-explorer-flutter'
2. Install dependencies: 'flutter pub get'
3. Connect a device or start an emulator
4. Run: `flutter run`

## How to Test Persistence

1. Open the app and save at least 5 favorites (tap heart icon on any Pokemon)
2. Force-close the app completely
3. Reopen the app and switch to the 'Favorites' tab
4. All saved Pokemon should still be there 

## Edge Cases Handled

1. Pokemon not found: Searching for a typo (e.g. "pikachu123") shows a friendly error with a Retry button instead of crashing
2. First launch / empty database: The Favorites screen shows a welcoming empty state message instead of a blank or crashed screen
3. No internet connection: The Browse screen shows a descriptive error message with a Retry button; previously saved favorites are still accessible offline