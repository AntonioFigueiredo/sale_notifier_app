import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(SaleNotifierApp());
}

class SaleNotifierApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sale Notifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  @override
  _GameListScreenState createState() => _GameListScreenState();
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/game_data.json');
}

class _GameListScreenState extends State<GameListScreen> {
  // Change the type to List<Map<String, dynamic>> for flexibility
  List<Map<String, dynamic>> games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  // Load the game data from the JSON file
  Future<void> _loadGames() async {
    try {
      String contents = await loadAsset();

      // Debugging: print the contents of the file
      print("File contents: $contents");

      // Parse the JSON string into a list of game objects
      List<dynamic> gameList = json.decode(contents);

      setState(() {
        // Convert the list of game data into a list of maps
        games = gameList.map((game) {
          return {
            'name': game['gameTitle'],
            'price': game['price'],
            'saleStatus': game['saleStatus'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading game data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Notifier'),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(games[index]['name'] ?? 'Unknown Game'),
            subtitle: Text(
                "Price: ${games[index]['price'] ?? 'N/A'}\nSale Status: ${games[index]['saleStatus'] ?? 'N/A'}"),
            leading: Icon(Icons.videogame_asset),
          );
        },
      ),
    );
  }
}
