import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';

void main() => runApp(SaleNotifierApp());

class SaleNotifierApp extends StatelessWidget {
  const SaleNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sale Notifier',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  GameListScreenState createState() => GameListScreenState();
}

class GameListScreenState extends State<GameListScreen> {
  final _fileLock = Lock();
  final _textFieldController = TextEditingController();
  final _logger = Logger();
  // static const _urlPattern = r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w- .\/?%&=]*)?$';

  late File _gameFile;
  List<Map<String, dynamic>> games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp().catchError((e) {
        _logger.e("Initialization error: $e");
        setState(() => _isLoading = false);
      });
    });
  }

  Future<void> _initializeApp() async {
    _logger.i("Initialization started");
    try {
      await _fileLock.synchronized(() async {
        await _setupFile();
        _logger.i("File setup complete");
        await createTestData();
        _logger.i("Test data created");
        await _loadGameData();
        _logger.i("Initialization complete");
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    _gameFile = File("${directory.path}/game_list.json");
    
    if (!await _gameFile.exists()) {
      await _gameFile.create(recursive: true);
      await _gameFile.writeAsString('[]');
    }
  }

  Future<void> _loadGameData() async {

    _logger.i("Loading game data from ${_gameFile.path}");
    try {

      String contents = await _gameFile.readAsString();
      if (contents.isEmpty) return;

      final gameList = json.decode(contents) as List<dynamic>;
      setState(() {
        // Sort games: on sale first
        gameList.sort((a, b) {
          final aOnSale = a['IsDiscounted'] == "on sale" ?  true : false;
          final bOnSale = b['IsDiscounted'] == "on sale" ?  true : false;
          
          // If both are on sale or not, maintain original order
          if (aOnSale == bOnSale) return 0;
          
          // Sort on sale items first
          return aOnSale ? -1 : 1;
        });

        // Map to final list
        games = gameList.map<Map<String, dynamic>>((game) => ({
          'name': game['GameTitle'],
          'price': game['DiscountedPrice'],
          'saleStatus': game['IsDiscounted'],
          'nsuid': game['Nsuid'],
      })).toList();
    });
    } catch (e) {
      _logger.e("Error loading game data: $e");
    }
  }

  Future<bool> _writeEntry(String url) async {
    if (url.isNotEmpty) {
      try {
        await MethodChannel('gonative_channel').invokeMethod('writeEntry', {
          "jsonFileName": _gameFile.path,
          "url": url,
        });
      } on PlatformException catch (e) {
        _logger.e("Failed to write entry: ${e.message}");
        return false;
      }
    }
    return true;
  }

  Future<void> _removeEntry(String nsuid) async {
    await _fileLock.synchronized(() async {
      try {
        await MethodChannel('gonative_channel').invokeMethod('removeEntry', {
          "jsonFileName": _gameFile.path,
          "nsuid": nsuid,
        });
      } on PlatformException catch (e) {
        _logger.e("Remove failed: ${e.message}");
      }
    });
  }

  Future<bool> _writeTestEntry(String url) async {
    if (url.isNotEmpty) {
      try {
        await MethodChannel('gonative_channel').invokeMethod('writeTestEntry', {
          "jsonFileName": _gameFile.path,
          "url": url,
        });
      } on PlatformException catch (e) {
        _logger.e("Failed to write test entry: ${e.message}");
        return false;
      }
    }
    return true;
  }

  Future<bool> _updateSingleGameData(String url) async {
    _logger.d("Updating game data for URL: $url");
    bool changedToSale = false;
    try {
      changedToSale = await MethodChannel('gonative_channel').invokeMethod(
        'updateEntry',
        {
          "jsonFileName": _gameFile.path,
          "url": url,
        },
      );
    } on PlatformException catch (e) {
      _logger.e("Update failed for URL $url: ${e.message}");
      return false;
    }
    if(changedToSale){
      _logger.i("Game on sale: $url");
    }
    return true;
  }

  Future<void> _updateAllGameData() async {
    _logger.d("Updating all game data");
    try {
      String contents = await _gameFile.readAsString();
      if (contents.isEmpty) return;

    final gameList = json.decode(contents) as List<dynamic>;
      
      for (final game in gameList) {
        final url = game['Url']?.toString();
        if (url != null && url.isNotEmpty) {
          await _updateSingleGameData(url);
        }
      }
    } catch (e) {
      _logger.e("Error updating game data: $e");
    }
  }

  Future<bool> createTestData() async {

    await _writeEntry("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Donkey-Kong-Country-Returns-HD-2590475.html");
    await _writeEntry("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Hogwarts-Legacy-2466200.html");
    await _writeTestEntry("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Mario-Rabbids-Sparks-of-Hope-1986931.html");
    await _writeTestEntry("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Download-Software/Disney-Dreamlight-Valley-2232608.html");
    await _writeTestEntry("https://www.nintendo.com/de-de/Spiele/Nintendo-Switch-Spiele/Mario-Luigi-Brothership-2590264.html");

    return true;
  }

  Future<void> _handleRefresh() async {
    _logger.d("Refreshing game data");
    Completer<void> completer = Completer<void>();

    try {
      await _fileLock.synchronized(() async {
        await _updateAllGameData();
        await _loadGameData();
        if (mounted) completer.complete();
      });
    } catch (e) {
      _logger.e("Refresh error: $e");
      if (mounted) {
        completer.complete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    return completer.future;
  }

  Future<void> _textFieldHandler(String value) async {
  final urlPattern = r'^(https?:\/\/)?([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,6})([\/\w .-]*)*\/?$';
  final isValidUrl = RegExp(urlPattern).hasMatch(value);

  if (!isValidUrl) {
    _logger.e("Invalid URL: $value");
    return;
  }

  try {
    setState(() => _isLoading = true);
    _logger.d("Processing URL: $value");

    await _fileLock.synchronized(() async {
      await _writeEntry(value);
      await _loadGameData();
    });
    
    _logger.i("Successfully processed URL: $value");
    } catch (e, stackTrace) {
      _logger.e("Error handling URL input", error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sale Notifier')),
      body: _isLoading
          ? _buildLoadingScreen()
          : games.isEmpty
            ? _buildEmptyState()
            : _buildGameList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        backgroundColor: Colors.green,
        shape: CircleBorder(),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 20),
          // Text(
          //   "Loading Games...",
          //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //         color: Colors.grey[600],
          //       ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Tap ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
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
    );
  }

  Widget _buildGameList() {
    return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.green,
        edgeOffset: 20,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: games.length,
          itemBuilder: (context, index) {
          final game = games[index];
          final isOnSale = game['saleStatus'] == "on sale";

          return Dismissible(
            key: Key(game['nsuid'] ?? index.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await _removeEntry(game['nsuid']);
              await _loadGameData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${game['name']} removed", style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 1),
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
                subtitle: Text(
                  "Price: ${game['price'] ?? 'N/A'}\nSale Status: ${isOnSale ? 'on sale' : 'not on sale'}",
                ),
                leading: Icon(Icons.videogame_asset),
              ),
            ),
          );
        },
      ),
    );
  }

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