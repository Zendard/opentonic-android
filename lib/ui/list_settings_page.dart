import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';
import 'package:opentonic/ui/home_page.dart';

class ListSettingsPage extends StatefulWidget {
  final int listId;
  const ListSettingsPage({super.key, required this.listId});

  @override
  createState() => _ListSettingsPageState();
}

class _ListSettingsPageState extends State<ListSettingsPage>
    with OpenTonicPageState {
  late OpenTonicAPI openTonicAPI;
  late OpenTonicList list;
  final listNameController = TextEditingController();
  late List<String> users = List.empty();
  var changed = false;
  var edited = false;

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

  void setList(int listId) async {
    try {
      final listLocal = await openTonicAPI.getList(widget.listId);
      setState(() {
        list = listLocal;
        pageState = PageState.ready();
        users = listLocal.users;
      });

      listNameController.text = list.name;
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  Future<void> updateList(String? name) async {
    try {
      openTonicAPI.updateList(widget.listId, name, users);
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  Future<void> deleteList(int listId) async {
    try {
      openTonicAPI.deleteList(widget.listId);
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  @override
  Widget buildReady(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${list.name} settings"),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(changed);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: listNameController,
                decoration: InputDecoration(
                  labelText: "List name",
                  border: OutlineInputBorder(),
                  hintText: "Groceries",
                ),
                autocorrect: true,
                keyboardType: TextInputType.text,
                onChanged: (_) {
                  setState(() {
                    edited = true;
                  });
                },
              ),
              SizedBox(
                height: 64,
                child: Wrap(
                  spacing: 16,
                  children: () {
                    List<Widget> usersChips = users
                        .map(
                          (user) => InputChip(
                            label: Text(user),
                            onDeleted: () {
                              setState(() {
                                users.remove(user);
                                edited = true;
                              });
                            },
                          ),
                        )
                        .toList();

                    usersChips.add(
                      InputChip(
                        label: Text("+"),
                        onPressed: () async {
                          final bool result = await showDialog(
                            context: context,
                            builder: (context) {
                              var addUserController = TextEditingController();
                              return SimpleDialog(
                                title: Text("Add user"),
                                contentPadding: EdgeInsets.all(16),
                                children: [
                                  TextField(
                                    controller: addUserController,
                                    decoration: InputDecoration(
                                      labelText: "User",
                                      border: OutlineInputBorder(),
                                      hintText: "Bob",
                                    ),
                                    keyboardType: TextInputType.name,
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        users.add(addUserController.text);
                                        edited = true;
                                      });
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text("Add"),
                                  ),
                                ],
                              );
                            },
                          );
                          if (!result) return;
                        },
                      ),
                    );

                    return usersChips;
                  }(),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Are you sure"),
                      content: Text("Do you really want to delete this list?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await deleteList(widget.listId);
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                              (_) => false,
                            );
                          },
                          child: Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: () {
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
      floatingActionButton: () {
        if (!edited) {
          return null;
        }

        return FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () {
            updateList(listNameController.text);
            setState(() {
              edited = false;
              changed = true;
            });
          },
        );
      }(),
    );
  }
}
