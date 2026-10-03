import 'package:material_ui/material_ui.dart';
import 'package:opentonic/net.dart';

class AddListPage extends StatefulWidget {
  const AddListPage({super.key});

  @override
  State<AddListPage> createState() => _AddListPageState();
}

class _AddListPageState extends State<AddListPage> {
  late OpenTonicAPI openTonicAPI;
  final addListNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    OpenTonicAPI.fromSharedPrefs().then((result) async {
      openTonicAPI = result;
    });
  }

  void addList(String listName) {
    openTonicAPI
        .addList(listName)
        .catchError((error) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(SnackBar(content: Text("Error:$error")));
          return 0;
        })
        .then((listId) {
          return listId;
        });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
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
            Navigator.of(context, rootNavigator: true).pop(true);
          },
        ),
        TextButton(
          onPressed: () async {
            addList(addListNameController.text);
            Navigator.of(context, rootNavigator: true).pop(true);
          },
          child: Text("Add list"),
        ),
      ],
    );
  }
}
