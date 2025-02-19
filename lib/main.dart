import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle, MethodChannel, PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

void main() => runApp(SaleNotifierApp());

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
  GameListScreenState createState() => GameListScreenState();
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/game_data.json');
}

void writeEntry(String url) async {
  final platform = MethodChannel('gonative_channel');
  var logger = Logger();
  final directory = await getApplicationDocumentsDirectory();
  File file = File("$directory/game_list.json");
    if (url.isNotEmpty) {
      try {
        await platform.invokeMethod('writeEntry', {
          "jsonFileName": file.path,
          "url": url,
        });
      } on PlatformException catch (e) {
        logger.e("Failed to write entry: ${e.message}");
      }
    }
}

void removeEntry(String nsuid) async {
  final platform = MethodChannel('gonative_channel');
  var logger = Logger();
  final directory = await getApplicationDocumentsDirectory();
  File file = File("$directory/game_list.json");
  if (nsuid.isNotEmpty) {
    try {
      await platform.invokeMethod('removeEntry', {
        "jsonFileName": file.path,
        "nsuid": nsuid,
      });
    } on PlatformException catch (e) {
      logger.e("Failed to remove entry: ${e.message}");
    }
  }
}

class GameListScreenState extends State<GameListScreen> {
  var logger = Logger();
  static final platform = MethodChannel('gonative_channel');
  // Change the type to List<Map<String, dynamic>> for flexibility
  List<Map<String, dynamic>> games = [];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
    final directory = await getApplicationDocumentsDirectory();
    File file = File("$directory/game_list.json");

    // Check if the file exists, if not create it
    if (!await file.exists()) {
      await file.create(recursive: true);
      // Optionally, write initial content to the file
      await file.writeAsString('[]');
    }

    String contents = await file.readAsString();
    List<dynamic> gameList = json.decode(contents);

    setState(() {
      games =
        gameList.map((game) {
          return {
            'name': game['GameTitle'],
            'price': game['DiscountedPrice'],
            'saleStatus': game['IsDiscounted'],
            'nsuid': game['Nsuid'],
          };
        }).toList();
    });
    } catch (e) {
      logger.e("Error loading game data: $e");
    }
  }

  Future<void> _textFieldHandler(String value) async {
    // var logger = Logger();
    logger.d("New URL $value");

    // Regular expression to validate URL
    final urlPattern = r'^(https?:\/\/)?([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,6})([\/\w .-]*)*\/?$';
    final isValidUrl = RegExp(urlPattern).hasMatch(value);

    if (!isValidUrl) {
      logger.e("Invalid URL: $value");
      return;
    }

    writeEntry(value);
    _loadGameData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sale Notifier')),
      body:
      games.isEmpty ?
      Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Press ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green, // Green background
            ),
            padding: EdgeInsets.all(6),
            child: Icon(Icons.add, color: Colors.white, size: 20),
          ),
          Text(
          " to add a new game",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    )
    : ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final isOnSale = game['saleStatus'] == "on sale";

          return Dismissible(
            key: Key(game['nsuid'] ?? index.toString()),  // Use nsuid as key if available
            direction: DismissDirection.endToStart, // Swipe from right to left
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              removeEntry(game['nsuid']);
              _loadGameData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${game['name']} removed", style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red, // Red background
                  duration: Duration(seconds: 1), // Show for 1 second
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: isOnSale
                  ? const Color.fromARGB(255, 87, 4, 18).withAlpha(60)
                  : Colors.transparent,
                border: isOnSale
                  ? Border.all(color: Color.fromARGB(255, 87, 4, 18), width: 2.0)
                  : null,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                title: Text(game['name'] ?? 'Unknown Game'),
                subtitle: Text("Price: ${game['price'] ?? 'N/A'}\nSale Status: ${isOnSale ? 'on sale' : 'not on sale'}",),
                leading: Icon(Icons.videogame_asset),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        backgroundColor: Colors.green,
        shape: CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }

  final TextEditingController _textFieldController = TextEditingController();
  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a new game'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "eShop URL"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                _textFieldController.clear();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                _textFieldHandler(_textFieldController.text);
                _textFieldController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
