import 'package:material_ui/material_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'ui/home_page.dart';

void main() {
  runApp(const MainApp());
}

class PageState {
  // 0 = Ready, 1 = Loading, 2 = Error
  final int _state;
  final dynamic _data;

  PageState(this._state, this._data);

  PageState.readyWithData(this._data) : _state = 0;
  PageState.ready() : _state = 0, _data = null;
  PageState.loading() : _state = 1, _data = null;
  PageState.error(dynamic error) : _state = 2, _data = error;

  bool isReady() => _state == 0;
  bool isLoading() => _state == 1;
  bool isError() => _state == 2;

  dynamic getData() {
    if (_state != 0) return null;
    return _data;
  }

  dynamic getError() {
    if (_state != 2) return null;
    return _data;
  }
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
