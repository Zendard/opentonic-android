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

mixin OpenTonicPageState {
  var pageState = PageState.loading();

  Widget buildReady(BuildContext context) {
    return Scaffold(appBar: AppBar());
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar();
  }

  Widget build(BuildContext context) {
    if (pageState.isLoading()) {
      return Scaffold(
        appBar: buildAppBar(context),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (pageState.isError()) {
      return Scaffold(
        appBar: buildAppBar(context),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 32),
              Text("An error has occurred:", style: TextStyle(fontSize: 32)),
              Container(
                padding: EdgeInsets.all(32),
                child: Text("${pageState.getError()}"),
              ),
            ],
          ),
        ),
      );
    }

    return buildReady(context);
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
  final List<String> users;

  const OpenTonicList({
    required this.id,
    required this.name,
    required this.owner,
    required this.users,
  });

  factory OpenTonicList.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "id": int id,
        "name": String name,
        "owner": String owner,
        "users": List<dynamic> users,
      } =>
        OpenTonicList(
          id: id,
          name: name,
          owner: owner,
          users: users.map((user) => user.toString()).toList(),
        ),
      _ => throw FormatException('Failed to parse List: ${json.toString()}'),
    };
  }
}

class OpenTonicListItem {
  final int id;
  final String name;
  final bool checked;
  final int productId;
  final String addedBy;
  final DateTime addedOn;

  const OpenTonicListItem({
    required this.id,
    required this.name,
    required this.checked,
    required this.productId,
    required this.addedBy,
    required this.addedOn,
  });

  factory OpenTonicListItem.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "id": int id,
        "name": String name,
        "checked": bool checked,
        "product_id": int productId,
        "added_by": String addedBy,
        "added_on": String addedOn,
      } =>
        OpenTonicListItem(
          id: id,
          name: name,
          checked: checked,
          productId: productId,
          addedBy: addedBy,
          addedOn: DateTime.parse(addedOn),
        ),
      _ => throw FormatException(
        'Failed to parse ListItem: ${json.toString()}',
      ),
    };
  }
}

class OpenTonicProduct {
  final int id;
  final String name;
  final int categoryId;

  const OpenTonicProduct({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  factory OpenTonicProduct.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {"id": int id, "name": String name, "category_id": int categoryId} =>
        OpenTonicProduct(id: id, name: name, categoryId: categoryId),
      _ => throw FormatException('Failed to parse Product: ${json.toString()}'),
    };
  }
}

class OpenTonicCategory {
  final int id;
  final String name;
  final String? iconId;
  final int orderIndex;

  const OpenTonicCategory({
    required this.id,
    required this.name,
    required this.iconId,
    required this.orderIndex,
  });

  factory OpenTonicCategory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "id": int id,
        "name": String name,
        "icon_id": String? iconId,
        "order_index": int orderIndex,
      } =>
        OpenTonicCategory(
          id: id,
          name: name,
          iconId: iconId,
          orderIndex: orderIndex,
        ),
      _ => throw FormatException(
        'Failed to parse Category: ${json.toString()}',
      ),
    };
  }
}
