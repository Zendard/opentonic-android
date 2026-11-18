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
    changed = true;
  }

  Future<void> deleteCategory(int categoryId) async {
    openTonicAPI.deleteCategory(widget.listId, categoryId);
    setState(() {
      categories.removeWhere((category) => category.id == categoryId);
    });
    changed = true;
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

  void reorderCategories(int categoryOldIndex, int categoryNewIndex) {
    final movedCategory = categories[categoryOldIndex];

    setState(() {
      categories.removeAt(categoryOldIndex);
      categories.insert(categoryNewIndex, movedCategory);
    });

    if (categoryNewIndex == categories.length - 1) {
      openTonicAPI.updateCategory(
        widget.listId,
        movedCategory.id,
        null,
        null,
        categories
                .lastWhere((category) => category.id != movedCategory.id)
                .orderIndex +
            1,
      );
      changed = true;
      return;
    }

    final nextCategory = categories[categoryNewIndex + 1];

    for (var index = categoryNewIndex; index < categories.length; index++) {
      final category = categories[index];
      openTonicAPI.updateCategory(
        widget.listId,
        category.id,
        null,
        null,
        nextCategory.orderIndex + index,
      );
    }
    changed = true;
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
      body: ReorderableListView.builder(
        buildDefaultDragHandles: true,
        onReorderItem: reorderCategories,
        padding: EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            key: ValueKey(category.id),
            title: Text(category.name),
            leading: ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_indicator),
            ),
            trailing: IconButton.filled(
              icon: Icon(Icons.delete),
              style: IconButton.styleFrom(
                backgroundColor: ColorScheme.of(context).error,
                foregroundColor: ColorScheme.of(context).onError,
              ),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Are you sure"),
                    content: Text(
                      "Do you really want to delete this category?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await deleteCategory(category.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showAddCategoryDialog(context),
      ),
    );
  }
}
