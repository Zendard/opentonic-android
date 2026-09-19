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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListPage(listId: list.id),
                      ),
                    );
                  },
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
                    padding: EdgeInsets.all(32),
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
            contentPadding: EdgeInsets.all(16),
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
                      .catchError((error) {
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
        padding: EdgeInsets.all(16),
        children: [
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Server Settings", style: TextStyle(fontSize: 24)),
              Card.filled(
                child: Container(
                  padding: EdgeInsets.all(16),
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

class ListPage extends StatefulWidget {
  final int listId;
  const ListPage({super.key, required this.listId});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late SharedPreferences prefs;
  late OpenTonicListFull list;
  late bool loaded = false;
  late List<int> listItemStates;

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPrefs();
    setList(widget.listId);
  }

  void setList(int listId) async {
    final listLocal = await fetchList(listId);
    setState(() {
      list = listLocal;
      listItemStates = listLocal.listItems
          .map((listItem) => listItem.checked ? 1 : 0)
          .toList();
      loaded = true;
    });
  }

  Future<OpenTonicListFull> fetchList(int listId) async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url");
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final authToken = base64Encode(utf8.encode("$username:$password"));
    final response = await http.get(
      Uri.parse("$serverUrl/api/list/$listId"),
      headers: {HttpHeaders.authorizationHeader: "Basic $authToken"},
    );

    if (response.statusCode == 200) {
      return OpenTonicListFull.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch list: $response");
    }
  }

  IconData categoryToIcon(String? category) {
    return switch (category) {
      "Fruit & Vegetables" => Icons.apple,
      "Meat" => Icons.outdoor_grill,
      "Vegetarian" => Icons.category,
      "Baking" => Icons.cake,
      _ => Icons.category,
    };
  }

  void setChecked(int listItemId, bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url");
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final authToken = base64Encode(utf8.encode("$username:$password"));
    final response = await http.post(
      Uri.parse("$serverUrl/api/check-list-item/$listItemId?checked=$checked"),
      headers: {HttpHeaders.authorizationHeader: "Basic $authToken"},
    );

    if (response.statusCode == 200) {
      setState(() {
        setList(widget.listId);
      });
    } else {
      throw Exception("Failed to fetch list: $response");
    }
  }

  List<Widget> listItemsToListTiles(List<OpenTonicListItem> listItems) {
    List<Widget> list = List.empty(growable: true);
    for (var i = 0; i < listItems.length; i++) {
      if (listItemStates[i] == 2) {
        list.add(
          ListTile(
            leading: Container(
              constraints: BoxConstraints.tightFor(width: 12, height: 12),
              margin: EdgeInsets.only(left: 16, right: 20),
              child: CircularProgressIndicator(),
            ),
            title: Text(listItems[i].name),
            trailing: Icon(categoryToIcon(listItems[i].category)),
          ),
        );
      } else {
        list.add(
          ListTile(
            title: Text(listItems[i].name),
            leading: Checkbox(
              value: listItemStates[i] == 1,
              onChanged: (_) {
                setState(() {
                  listItemStates[i] = 2;
                });
                setChecked(listItems[i].id, !listItems[i].checked);
              },
            ),
            dense: true,
            trailing: Icon(categoryToIcon(listItems[i].category)),
          ),
        );
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(list.name)),
        body: ListView(children: listItemsToListTiles(list.listItems)),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddListItemPage(listId: widget.listId),
              ),
            );
            if (result) {
              setState(() {
                loaded = false;
                setList(widget.listId);
              });
            }
          },
        ),
      );
    }
    return Center(child: CircularProgressIndicator());
  }
}

class OpenTonicListFull {
  final String name;
  final String owner;
  final List<String> users;
  final List<OpenTonicListItem> listItems;

  const OpenTonicListFull({
    required this.name,
    required this.owner,
    required this.users,
    required this.listItems,
  });

  factory OpenTonicListFull.fromJson(Map<String, dynamic> json) {
    final jsonStr = json.toString();
    return switch (json) {
      {
        "name": String name,
        "owner": String owner,
        "users": List<dynamic> users,
        "list_items": List<dynamic> listItems,
      } =>
        OpenTonicListFull(
          name: name,
          owner: owner,
          users: users.map((user) => user.toString()).toList(),
          listItems: listItems
              .map((listItem) => OpenTonicListItem.fromJson(listItem))
              .toList(),
        ),
      _ => throw FormatException('Failed to fetch list: $jsonStr'),
    };
  }
}

class OpenTonicListItem {
  final int id;
  final String name;
  final bool checked;
  final String? category;
  final String addedBy;
  final DateTime addedOn;

  const OpenTonicListItem({
    required this.id,
    required this.name,
    required this.checked,
    required this.category,
    required this.addedBy,
    required this.addedOn,
  });

  factory OpenTonicListItem.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "id": int id,
        "name": String name,
        "checked": bool checked,
        "category": String? category,
        "added_by": String addedBy,
        "added_on": String addedOn,
      } =>
        OpenTonicListItem(
          id: id,
          name: name,
          checked: checked,
          category: category,
          addedBy: addedBy,
          addedOn: DateTime.parse(addedOn),
        ),
      _ => throw FormatException(
        'Failed to parse ListItem: ${json.toString()}',
      ),
    };
  }
}

class AddListItemPage extends StatefulWidget {
  final int listId;
  const AddListItemPage({super.key, required this.listId});

  @override
  State<AddListItemPage> createState() => _AddListItemPageState();
}

class _AddListItemPageState extends State<AddListItemPage> {
  late SharedPreferences prefs;
  final itemNameController = TextEditingController();
  final itemNameFocusNode = FocusNode();
  var changed = false;
  var addingListItem = false;

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<int> addListItem(String listItemName, int listId) async {
    setState(() {
      addingListItem = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url");
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final authToken = base64Encode(utf8.encode("$username:$password"));
    final response = await http.post(
      Uri.parse("$serverUrl/api/add-list-item/$listId"),
      headers: {
        HttpHeaders.authorizationHeader: "Basic $authToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode({"name": listItemName}),
    );

    if (response.statusCode == 200) {
      changed = true;
      setState(() {
        addingListItem = false;
      });
      return int.parse(response.body);
    } else {
      throw Exception("Failed to add list item: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () async {
            if (itemNameController.text.isNotEmpty) {
              await addListItem(itemNameController.text, widget.listId);
              itemNameController.clear();
              itemNameFocusNode.requestFocus();
            }
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop(changed);
          },
        ),
        title: Text("Add list item"),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: itemNameController,
              focusNode: itemNameFocusNode,
              decoration: InputDecoration(
                labelText: "Item name",
                border: OutlineInputBorder(),
                hintText: "Apples",
              ),
              autocorrect: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  addListItem(value, widget.listId);
                  itemNameController.clear();
                  itemNameFocusNode.requestFocus();
                }
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(title: Text("Apple"), leading: Icon(Icons.add)),
                ListTile(title: Text("Cookies"), leading: Icon(Icons.add)),
                ListTile(title: Text("Flour"), leading: Icon(Icons.add)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: () {
          if (addingListItem) {
            return CircularProgressIndicator();
          }
          return Icon(Icons.check);
        }(),
        onPressed: () async {
          if (itemNameController.text.isNotEmpty) {
            changed = true;
            await addListItem(itemNameController.text, widget.listId);
            itemNameController.clear();
            itemNameFocusNode.requestFocus();
          }

          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop(changed);
        },
      ),
    );
  }
}
