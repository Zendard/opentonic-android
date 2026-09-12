import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;
        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.lightBlue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.lightBlue,
            brightness: Brightness.dark,
          );
        }
        return MaterialApp(
          title: 'OpenTonic',
          home: const HomePage(),
          theme: ThemeData(colorScheme: lightColorScheme),
          darkTheme: ThemeData(colorScheme: darkColorScheme),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<OpenTonicList>> futureLists;
  late SharedPreferences prefs;
  final addListNameController = TextEditingController();
  late bool loaded = false;

  @override
  void initState() {
    super.initState();
    futureLists = fetchLists();
  }

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
      loaded = true;
    });
  }

  Future<List<OpenTonicList>> fetchLists() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url");
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final authToken = base64Encode(utf8.encode("$username:$password"));
    final response = await http.get(
      Uri.parse("$serverUrl/api/lists"),
      headers: {HttpHeaders.authorizationHeader: "Basic $authToken"},
    );

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicList.fromJson(str)).toList();
    } else {
      throw Exception("Failed to fetch lists");
    }
  }

  Future<int> addList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url");
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final authToken = base64Encode(utf8.encode("$username:$password"));

    final response = await http.post(
      Uri.parse("$serverUrl/api/create-list"),
      headers: {
        HttpHeaders.authorizationHeader: "Basic $authToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode({"name": listName}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["id"];
    } else {
      throw Exception("Failed to add list: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OpenTonic"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: futureLists,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var listItems = snapshot.data!.map((list) {
              return Card(
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Text(list.owner),
                  leading: Icon(Icons.storefront),
                ),
              );
            }).toList();
            return ListView(children: listItems);
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 32),
                  Text(
                    "An error has occurred:",
                    style: TextStyle(fontSize: 32),
                  ),
                  Container(
                    padding: EdgeInsetsGeometry.all(32),
                    child: Text("${snapshot.error}"),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text("Add list"),
            contentPadding: EdgeInsetsGeometry.all(16),
            children: [
              TextField(
                controller: addListNameController,
                decoration: InputDecoration(
                  labelText: "List name",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                onSubmitted: (value) {
                  addList(value);
                },
              ),
              TextButton(
                onPressed: () {
                  addList(addListNameController.text)
                      .onError((error) {
                        if (!context.mounted) return 0;
                        Navigator.pop(context);
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error:$error")),
                        );
                        return 0;
                      })
                      .then((_) {
                        if (!context.mounted) return 0;
                        Navigator.pop(context);
                        setState(() {
                          futureLists = fetchLists();
                        });
                      });
                },
                child: Text("Add list"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool loaded = false;
  late SharedPreferences prefs;
  final serverUrlContoller = TextEditingController();
  final usernameContoller = TextEditingController();
  final passwordContoller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
      loaded = true;
      serverUrlContoller.text = prefs.getString("server-url") ?? "";
      usernameContoller.text = prefs.getString("username") ?? "";
      passwordContoller.text = prefs.getString("password") ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: Text("Settings")),
        body: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        padding: EdgeInsetsGeometry.all(16),
        children: [
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Server Settings", style: TextStyle(fontSize: 24)),
              Card.filled(
                child: Container(
                  padding: EdgeInsetsGeometry.all(16),
                  child: Column(
                    spacing: 16,
                    children: [
                      TextField(
                        controller: serverUrlContoller,
                        decoration: InputDecoration(
                          labelText: "Server URL",
                          border: OutlineInputBorder(),
                          hintText: "https://server.example:port/subdirectory",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                        onSubmitted: (value) {
                          prefs.setString("server-url", value);
                        },
                      ),
                      TextField(
                        controller: usernameContoller,
                        decoration: InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(),
                          hintText: "admin",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.name,
                        onSubmitted: (value) {
                          prefs.setString("username", value);
                        },
                      ),
                      TextField(
                        controller: passwordContoller,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          hintText: "password",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        onSubmitted: (value) {
                          prefs.setString("password", value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddListPage extends StatefulWidget {
  const AddListPage({super.key});

  @override
  State<AddListPage> createState() => _AddListPageState();
}

class _AddListPageState extends State<AddListPage> {
  late bool loaded = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        appBar: AppBar(title: Text("Add List")),
        body: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Add List")),
      body: TextField(),
    );
  }
}

class OpenTonicList {
  final int id;
  final String name;
  final String owner;

  const OpenTonicList({
    required this.id,
    required this.name,
    required this.owner,
  });

  factory OpenTonicList.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {"id": int id, "name": String name, "owner": String owner} =>
        OpenTonicList(id: id, name: name, owner: owner),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}
