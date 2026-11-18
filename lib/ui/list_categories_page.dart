import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';

class ListCategoriesPage extends StatefulWidget {
  final int listId;
  const ListCategoriesPage({super.key, required this.listId});

  @override
  createState() => _ListCategoriesPageState();
}

class _ListCategoriesPageState extends State<ListCategoriesPage>
    with OpenTonicPageState {
  late OpenTonicAPI openTonicAPI;
  late List<OpenTonicCategory> categories;
  var changed = false;
  var edited = false;

  @override
  void initState() {
    super.initState();
    initStateAsync(context);
  }

  void initStateAsync(BuildContext context) async {
    try {
      openTonicAPI = await OpenTonicAPI.fromSharedPrefs();
      categories = await openTonicAPI.getCategories(widget.listId);
      categories.sort(
        (categoryA, categoryB) =>
            categoryA.orderIndex.compareTo(categoryB.orderIndex),
      );
      setState(() {
        pageState = PageState.ready();
      });
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  Future<void> addCategory(String categoryName, String categoryIcon) async {
    await openTonicAPI.createCategory(
      widget.listId,
      categoryName,
      categoryIcon == "" ? null : categoryIcon,
    );
  }

  void showAddCategoryDialog(BuildContext context) async {
    final categoryNameController = TextEditingController();
    final categoryIconController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Add category"),
        contentPadding: EdgeInsets.all(16),

        children: [
          Column(
            spacing: 24,
            children: [
              TextField(
                controller: categoryNameController,
                decoration: InputDecoration(
                  labelText: "Category name",
                  border: OutlineInputBorder(),
                  hintText: "Fruit & Veg",
                ),
                autocorrect: true,
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: categoryIconController,
                decoration: InputDecoration(
                  labelText: "Category icon id (optional)",
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                keyboardType: TextInputType.text,
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await addCategory(
                    categoryNameController.text,
                    categoryIconController.text,
                  );
                  if (!context.mounted) return;
                  setState(() {
                    pageState = PageState.loading();
                  });
                  Navigator.of(context).pop();
                  initStateAsync(context);
                },
                child: Text("Add"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildReady(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit categories"),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(changed);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: (oldIndex, newIndex) {},
            children: categories
                .map(
                  (category) => ListTile(
                    key: ValueKey(category.id),
                    title: Text(category.name),
                  ),
                )
                .toList(),
          ),
          TextButton.icon(
            onPressed: () => showAddCategoryDialog(context),
            icon: Icon(Icons.add),
            label: Text("Add category"),
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
