import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';

class ListSettingsPage extends StatefulWidget {
  final int listId;
  const ListSettingsPage({super.key, required this.listId});

  @override
  State<ListSettingsPage> createState() => _ListSettingsPageState();
}

class _ListSettingsPageState extends State<ListSettingsPage> {
  late OpenTonicAPI openTonicAPI;
  late OpenTonicListFull list;
  var pageState = PageState.loading();
  final listNameController = TextEditingController();
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
      final listLocal = await openTonicAPI.list(widget.listId);
      setState(() {
        list = listLocal;
        pageState = PageState.ready();
      });

      listNameController.text = list.name;
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pageState.isLoading()) {
      return Scaffold(
        appBar: AppBar(title: Text("List settings")),
        body: Center(child: CircularProgressIndicator()),
      );
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
                    List<Widget> users = list.users
                        .map(
                          (user) => InputChip(
                            label: Text(user),
                            onDeleted: () {
                              // Delete user from list
                              changed = true;
                            },
                          ),
                        )
                        .toList();

                    users.add(
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
                                      await openTonicAPI
                                          .addUserToList(
                                            widget.listId,
                                            addUserController.text,
                                          )
                                          .catchError((error) async {
                                            if (!context.mounted) return "";
                                            Navigator.of(context).pop(true);
                                            await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("An error occured"),
                                                icon: Icon(Icons.error),
                                                content: Text(error.toString()),
                                              ),
                                            );
                                            return "";
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
                          setList(widget.listId);
                        },
                      ),
                    );

                    return users;
                  }(),
                ),
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
            // Update list
            setState(() {
              edited = false;
            });
            changed = true;
          },
        );
      }(),
    );
  }
}
