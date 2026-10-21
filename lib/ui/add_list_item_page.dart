import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';

class AddListItemPage extends StatefulWidget {
  final int listId;
  const AddListItemPage({super.key, required this.listId});

  @override
  State<AddListItemPage> createState() => _AddListItemPageState();
}

class _AddListItemPageState extends State<AddListItemPage>
    with OpenTonicPageState {
  late OpenTonicAPI openTonicAPI;
  final itemNameController = TextEditingController();
  final itemNameFocusNode = FocusNode();
  var changed = false;
  var addingListItem = false;
  late List<OpenTonicProduct> suggestions = List.empty();

  @override
  void initState() {
    super.initState();
    () async {
      openTonicAPI = await OpenTonicAPI.fromSharedPrefs();
    }();
  }

  Future<OpenTonicListItem> addListItem(String listItemName, int listId) async {
    setState(() {
      addingListItem = true;
    });
    final listItemId = await openTonicAPI.createListItem(listId, listItemName);
    changed = true;
    setState(() {
      addingListItem = false;
    });
    return listItemId;
  }

  Future<void> updateSuggestions(int listId, String query) async {
    final suggestionsLocal = await openTonicAPI.queryProducts(listId, query);
    setState(() {
      suggestions = suggestionsLocal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (itemNameController.text.isNotEmpty) {
          setState(() {
            addingListItem = true;
          });
          changed = true;
          await addListItem(itemNameController.text, widget.listId);
          itemNameController.clear();
        }

        if (!context.mounted || didPop) return;
        Navigator.of(context).pop(changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Add list item")),
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
                    updateSuggestions(widget.listId, "");
                    itemNameFocusNode.requestFocus();
                  }
                },
                onChanged: (value) {
                  updateSuggestions(widget.listId, value);
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: () {
                  return suggestions
                      .map(
                        (product) => GestureDetector(
                          onTap: () {
                            addListItem(itemNameController.text, widget.listId);
                            itemNameController.clear();
                            updateSuggestions(widget.listId, "");
                            itemNameFocusNode.requestFocus();
                          },
                          child: ListTile(
                            title: Text(product.name),
                            leading: Icon(Icons.add),
                          ),
                        ),
                      )
                      .toList();
                }(),
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
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }
}
