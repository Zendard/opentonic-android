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

class ListItemUI {
  final OpenTonicListItem listItem;
  ListItemState state;

  ListItemUI({required this.listItem, required this.state});

  static Future<ListItemUI> fromListItem(
    int listId,
    OpenTonicListItem listItem,
  ) async {
    final state = listItem.checked
        ? ListItemState.checked
        : ListItemState.unchecked;

    return ListItemUI(listItem: listItem, state: state);
  }
}

class CategoryUI {
  final OpenTonicCategory category;
  final Widget icon;

  CategoryUI({required this.category, required this.icon});

  static Future<CategoryUI> fromOpenTonicAPI(
    int listId,
    int categoryId,
    Color iconFill,
    OpenTonicAPI openTonicAPI,
  ) async {
    final category = await openTonicAPI.getCategory(listId, categoryId);
    late Widget iconLocal;
    if (category.iconId != null) {
      final iconStr = await openTonicAPI.getIcon(category.iconId!);

      final iconFilter = ColorFilter.mode(iconFill, BlendMode.srcIn);
      iconLocal = SvgPicture.string(iconStr, colorFilter: iconFilter);
    } else {
      iconLocal = Icon(Icons.category);
    }

    return CategoryUI(category: category, icon: iconLocal);
  }

  static Future<CategoryUI> fromCategory(
    OpenTonicCategory category,
    Color iconFill,
    OpenTonicAPI openTonicAPI,
  ) async {
    late Widget iconLocal;
    if (category.iconId != null) {
      final iconStr = await openTonicAPI.getIcon(category.iconId!);

      final iconFilter = ColorFilter.mode(iconFill, BlendMode.srcIn);
      iconLocal = SvgPicture.string(iconStr, colorFilter: iconFilter);
    } else {
      iconLocal = Icon(Icons.category);
    }

    return CategoryUI(category: category, icon: iconLocal);
  }
}

class _ListPageState extends State<ListPage> with OpenTonicPageState {
  late OpenTonicList list;
  late List<ListItemUI> listItems;
  late List<CategoryUI> categories;
  late OpenTonicAPI openTonicAPI;
  late String? user;

  @override
  void initState() {
    super.initState();
    initStateAsync(context).catchError((e) {
      setState(() {
        pageState = PageState.error(e);
      });
    });
  }

  Future<void> initStateAsync(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString("username");
    openTonicAPI = await OpenTonicAPI.fromSharedPrefs();

    list = await openTonicAPI.getList(widget.listId);
    final localListItems = await openTonicAPI.getListItems(widget.listId);
    listItems = List.empty(growable: true);
    if (!context.mounted) return;
    final colorScheme = ColorScheme.of(context);

    for (var listItem in localListItems) {
      listItems.add(await ListItemUI.fromListItem(widget.listId, listItem));
    }

    final localCategories = await openTonicAPI.getCategories(widget.listId);
    categories = List.empty(growable: true);

    for (var category in localCategories) {
      categories.add(
        await CategoryUI.fromCategory(
          category,
          colorScheme.primary,
          openTonicAPI,
        ),
      );
    }

    categories.sort((a, b) => a.category.id - b.category.id);

    setState(() {
      pageState = PageState.ready();
    });
  }

  String addedOnToString(DateTime addedOn) {
    if (DateTime.now().difference(addedOn) <= Duration(days: 1)) {
      return "at ${addedOn.hour.toString().padLeft(2, "0")}:${addedOn.minute.toString().padLeft(2, "0")}";
    } else {
      return "on ${addedOn.day.toString().padLeft(2, "0")}/${addedOn.month.toString().padLeft(2, "0")}";
    }
  }

  void _showListItemBottomSheet(int listItemIndex) {
    final listItem = listItems[listItemIndex].listItem;
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {
          setState(() {
            pageState = PageState.loading();
          });
          setState(() async {
            await initStateAsync(context);
          });
        },
        builder: (context) => Container(
          padding: EdgeInsets.all(32),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: Text(listItem.name, style: TextStyle(fontSize: 32)),
                  ),
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton.filledTonal(
                      icon: Center(
                        child: categories[listItem.categoryId - 1].icon,
                      ),
                      onPressed: () =>
                          _showChangeCategoryDialog(listItemIndex, context),
                    ),
                  ),
                ],
              ),
              Text(
                "Added by ${listItem.addedBy} ${addedOnToString(listItem.addedOn)}",
              ),
              IconButton.filled(
                icon: () {
                  if (listItems[listItemIndex].state == ListItemState.loading) {
                    return CircularProgressIndicator();
                  }
                  return Icon(Icons.delete);
                }(),
                style: IconButton.styleFrom(
                  backgroundColor: ColorScheme.of(context).error,
                ),
                onPressed: () async {
                  setState(() {
                    listItems[listItemIndex].state = ListItemState.loading;
                  });

                  if (!context.mounted) return;
                  Navigator.of(context).pop();

                  await openTonicAPI.deleteListItem(widget.listId, listItem.id);

                  setState(() {
                    listItems.removeAt(listItemIndex);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeCategoryDialog(
    int listItemIndex,
    BuildContext context,
  ) async {
    final listItemUI = listItems[listItemIndex];

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Choose a category"),
        children: categories
            .map(
              (categoryUI) => SimpleDialogOption(
                onPressed: () async {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  setState(() {
                    listItems[listItemIndex].state = ListItemState.loading;
                  });

                  await openTonicAPI.updateProduct(
                    widget.listId,
                    listItemUI.listItem.productId,
                    null,
                    categoryUI.category.id,
                  );

                  final listItem = await openTonicAPI.getListItem(
                    widget.listId,
                    listItemUI.listItem.id,
                  );

                  final localListItemUI = await ListItemUI.fromListItem(
                    widget.listId,
                    listItem,
                  );

                  setState(() {
                    listItems[listItemIndex] = localListItemUI;
                  });
                },
                child: Row(
                  spacing: 16,
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child: IconButton.filledTonal(
                        onPressed: () {},
                        icon: categoryUI.icon,
                      ),
                    ),
                    Text(categoryUI.category.name),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
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
                  initStateAsync(context);
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
            initStateAsync(context);
          });
        },
        child: Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return initStateAsync(context);
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: () {
            List<Widget> list = List.empty(growable: true);
            for (var i = 0; i < listItems.length; i++) {
              list.add(
                ListTile(
                  title: GestureDetector(
                    onTap: () => _showListItemBottomSheet(i),
                    child: Text(listItems[i].listItem.name),
                  ),
                  leading: SizedBox.square(
                    dimension: 16,
                    child: () {
                      if (listItems[i].state == ListItemState.loading) {
                        return CircularProgressIndicator();
                      }

                      return Checkbox(
                        value: listItems[i].state == ListItemState.checked,
                        onChanged: (checked) async {
                          setState(() {
                            listItems[i].state = ListItemState.loading;
                            initStateAsync(context);
                          });

                          await openTonicAPI.updateListItem(
                            widget.listId,
                            listItems[i].listItem.id,
                            checked == true,
                          );

                          setState(() {
                            listItems[i].state = checked == true
                                ? ListItemState.checked
                                : ListItemState.unchecked;
                          });
                        },
                      );
                    }(),
                  ),
                  trailing: SizedBox.square(
                    dimension: 32,
                    child:
                        categories[listItems[i].listItem.categoryId - 1].icon,
                  ),
                ),
              );
            }
            return list;
          }(),
        ),
      ),
    );
  }
}
