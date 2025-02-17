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
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: ThemeMode.system, // Use system theme
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
      await platform.invokeMethod('writeEntry', {
        "jsonFileName": file.path,
        "url":
            "https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Download-Software/Disney-Dreamlight-Valley-2232608.html",
      });
      // await platform.invokeMethod('removeEntry', {
      //   "jsonFileName": file.path,
      //   "nsuid": "70010000084603",
      // });

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
      body:
          games.isEmpty
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final isOnSale = game['saleStatus'] == "on sale";

                  return Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isOnSale
                              ? const Color.fromARGB(
                                255,
                                87,
                                4,
                                18,
                              ).withAlpha(60)
                              : Colors.transparent,
                      border:
                          isOnSale
                              ? Border.all(
                                color: Color.fromARGB(255, 87, 4, 18),
                                width: 2.0,
                              )
                              : null,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(game['name'] ?? 'Unknown Game'),
                      subtitle: Text(
                        "Price: ${game['price'] ?? 'N/A'}\nSale Status: ${isOnSale ? 'on sale' : 'not on sale'}",
                      ),
                      leading: Icon(Icons.videogame_asset),
                    ),
                  );
                },
              ),
    );
  }
}
