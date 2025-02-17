import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(SaleNotifierApp());
}

class SaleNotifierApp extends StatelessWidget {
  const SaleNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sale Notifier',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/game_data.json');
}

class _GameListScreenState extends State<GameListScreen> {
  static final platform = MethodChannel('gonative_channel');
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
      final directory = await getApplicationDocumentsDirectory();
      File file = File("$directory/game_list.json"); // await _localFile;
      print("File path: ${file.path}");

      // Check if the file exists, if not create it
      if (!await file.exists()) {
        await file.create(recursive: true);
        // Optionally, write initial content to the file
        await file.writeAsString('[]');
      }

      await platform.invokeMethod('writeEntry', {
        "jsonFileName": file.path,
        "url":
            "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Donkey-Kong-Country-Returns-HD-2590475.html",
      });

      String contents = await file.readAsString();

      // Parse the JSON string into a list of game objects
      List<dynamic> gameList = json.decode(contents);

      setState(() {
        // Convert the list of game data into a list of maps
        games =
            gameList.map((game) {
              return {
                'name': game['GameTitle'],
                'price': game['DiscountedPrice'],
                'saleStatus': game['IsDiscounted'],
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
      appBar: AppBar(title: Text('Sale Notifier')),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(games[index]['name'] ?? 'Unknown Game'),
            subtitle: Text(
              "Price: ${games[index]['price'] ?? 'N/A'}\nSale Status: ${games[index]['saleStatus'] ?? 'N/A'}",
            ),
            leading: Icon(Icons.videogame_asset),
          );
        },
      ),
    );
  }
}
