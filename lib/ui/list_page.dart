import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';
import 'package:opentonic/ui/add_list_item_page.dart';
import 'package:opentonic/ui/list_settings_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPage extends StatefulWidget {
  final int listId;
  const ListPage({super.key, required this.listId});

  @override
  State<ListPage> createState() => _ListPageState();
}

enum ListItemState { unchecked, loading, checked }

class _ListPageState extends State<ListPage> with OpenTonicPageState {
  late OpenTonicList list;
  late HashMap<OpenTonicListItem, ListItemState> listItems;
  late HashMap<OpenTonicListItem, String> icons;
  late OpenTonicAPI openTonicAPI;
  late String? user;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString("username");
    openTonicAPI = await OpenTonicAPI.fromSharedPrefs();

    list = await openTonicAPI.getList(widget.listId);
    final localListItems = await openTonicAPI.getListItems(widget.listId);
    listItems = HashMap();
    icons = HashMap();
    for (var listItem in localListItems) {
      listItems[listItem] = listItem.checked
          ? ListItemState.checked
          : ListItemState.unchecked;
      final product = await openTonicAPI.getProduct(
        widget.listId,
        listItem.productId,
      );

      final category = await openTonicAPI.getCategory(
        widget.listId,
        product.categoryId,
      );
      final iconId = category.iconId;

      if (iconId != null) {
        icons[listItem] = await openTonicAPI.getIcon(iconId);
      }
    }

    setState(() {
      pageState = PageState.ready();
    });
  }

  @override
  Widget buildReady(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: () {
          if (list.owner != user) return null;
          return [
            IconButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListSettingsPage(listId: widget.listId),
                  ),
                );

                if (!result) return;

                setState(() {
                  pageState = PageState.loading();
                });
                setState(() async {
                  initStateAsync();
                });
              },
              icon: Icon(Icons.settings),
            ),
          ];
        }(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddListItemPage(listId: widget.listId),
            ),
          );

          if (!result) return;

          setState(() {
            pageState = PageState.loading();
          });
          setState(() async {
            initStateAsync();
          });
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: () {
          return listItems.keys
              .map(
                (listItem) => ListTile(
                  title: Text(listItem.name),
                  leading: SizedBox.square(
                    dimension: 16,
                    child: () {
                      if (listItems[listItem] == ListItemState.loading) {
                        return CircularProgressIndicator();
                      }

                      return Checkbox(
                        value: listItems[listItem] == ListItemState.checked,
                        onChanged: (checked) async {
                          setState(() {
                            listItems[listItem] = ListItemState.loading;
                            initStateAsync();
                          });

                          await openTonicAPI.updateListItem(
                            widget.listId,
                            listItem.id,
                            checked == true,
                          );

                          setState(() {
                            listItems[listItem] = checked == true
                                ? ListItemState.checked
                                : ListItemState.unchecked;
                          });
                        },
                      );
                    }(),
                  ),
                  trailing: () {
                    final icon = icons[listItem];
                    if (icon == null) {
                      return Icon(Icons.category);
                    } else {
                      return SvgPicture.string(icon);
                    }
                  }(),
                ),
              )
              .toList();
        }(),
      ),
    );
  }
}
