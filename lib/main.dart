import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    futureLists = fetchLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OpenTonic")),
      body: FutureBuilder(
        future: futureLists,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var listItems = snapshot.data!.map((list) {
              return ListTile(
                title: Text(list.name),
                subtitle: Text(list.owner),
                leading: Icon(Icons.storefront),
              );
            }).toList();
            return ListView(children: listItems);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          return const CircularProgressIndicator();
        },
      ),
      // ListTile(
      //   title: Text("Jumbo"),
      //   subtitle: Text("Mama"),
      //   leading: Icon(Icons.storefront),
      // ),
    );
  }
}

Future<List<OpenTonicList>> fetchLists() async {
  const serverUrl = "http://10.0.2.2:8080/opentonic";
  const authToken = "dGhpanM6dGhpanM=";
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
