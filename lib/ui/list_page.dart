import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';
import 'package:opentonic/ui/add_list_item_page.dart';
import 'package:opentonic/ui/list_settings_page.dart';

class ListPage extends StatefulWidget {
  final int listId;
  const ListPage({super.key, required this.listId});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late OpenTonicAPI openTonicAPI;
  late OpenTonicListFull list;
  var pageState = PageState.loading();
  late List<int> listItemStates;

  @override
  void initState() {
    super.initState();
    () async {
      try {
        openTonicAPI = await OpenTonicAPI.fromSharedPrefs();
        setList(widget.listId);
      } catch (e) {
        pageState = PageState.error(e);
      }
    }();
  }

  Future<void> setList(int listId) async {
    try {
      final listLocal = await openTonicAPI.list(listId);
      setState(() {
        list = listLocal;
        listItemStates = listLocal.listItems
            .map((listItem) => listItem.checked ? 1 : 0)
            .toList();
        pageState = PageState.ready();
      });
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
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
    await openTonicAPI.setChecked(listItemId, checked);
    setState(() {
      setList(widget.listId);
    });
  }

  String formatAddedOn(DateTime addedOn) {
    if (DateTime.now().difference(addedOn) <= Duration(days: 1)) {
      return "at ${addedOn.hour.toString().padLeft(2, "0")}:${addedOn.minute.toString().padLeft(2, "0")}";
    } else {
      return "on ${addedOn.day.toString().padLeft(2, "0")}/${addedOn.month.toString().padLeft(2, "0")}";
    }
  }

  List<Widget> listItemsToListTiles(List<OpenTonicListItem> listItems) {
    List<Widget> list = List.empty(growable: true);
    for (var i = 0; i < listItems.length; i++) {
      list.add(
        ListTile(
          leading: Container(
            constraints: BoxConstraints.tightFor(width: 12, height: 12),
            margin: EdgeInsets.only(left: 16, right: 20),
            child: () {
              if (listItemStates[i] == 2) {
                return CircularProgressIndicator();
              }
              return Checkbox(
                value: listItemStates[i] == 1,
                onChanged: (_) {
                  setState(() {
                    listItemStates[i] = 2;
                  });
                  setChecked(listItems[i].id, !listItems[i].checked);
                },
              );
            }(),
          ),
          title: Text(listItems[i].name),
          trailing: Icon(categoryToIcon(listItems[i].category)),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) => Container(
                    padding: EdgeInsets.all(64),
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listItems[i].name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Icon(categoryToIcon(listItems[i].category)),
                          ],
                        ),
                        Expanded(
                          child: Text(
                            "Added by ${listItems[i].addedBy} ${formatAddedOn(listItems[i].addedOn)}",
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton(
                              onPressed: () async {
                                setState(() {
                                  listItemStates[i] = 3;
                                });
                                await openTonicAPI.deleteListItem(
                                  listItems[i].id,
                                );
                                await setList(widget.listId);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .error,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onError,
                              ),
                              child: () {
                                if (listItemStates[i] == 3) {
                                  return SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onError,
                                    ),
                                  );
                                }
                                return SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Icon(Icons.delete),
                                );
                              }(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (pageState.isLoading()) {
      return Center(child: CircularProgressIndicator());
    } else if (pageState.isError()) {
      return Scaffold(
        appBar: AppBar(),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: () {
          List<Widget> actions = [];
          if (list.owner != openTonicAPI.username) return actions;
          actions.add(
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListSettingsPage(listId: widget.listId),
                  ),
                );
              },
              icon: Icon(Icons.settings),
            ),
          );
          return actions;
        }(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await setList(widget.listId);
          return;
        },
        child: ListView(children: listItemsToListTiles(list.listItems)),
      ),
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
              pageState = PageState.loading();
              setList(widget.listId);
            });
          }
        },
      ),
    );
  }
}
