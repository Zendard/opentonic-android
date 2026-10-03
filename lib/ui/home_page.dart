import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';
import 'package:opentonic/ui/add_list_page.dart';
import 'package:opentonic/ui/list_page.dart';
import 'package:opentonic/ui/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late OpenTonicAPI openTonicAPI;
  late List<OpenTonicList> lists;
  var pageState = PageState.loading();
  final addListNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    () async {
      openTonicAPI = await OpenTonicAPI.fromSharedPrefs();
      try {
        lists = await openTonicAPI.lists();
        setState(() {
          pageState = PageState.ready();
        });
      } catch (e) {
        setState(() {
          pageState = PageState.error(e);
        });
      }
    }();
  }

  void refreshLists() async {
    setState(() {
      pageState = PageState.loading();
    });

    try {
      openTonicAPI = await OpenTonicAPI.fromSharedPrefs();
      lists = await openTonicAPI.lists();
      setState(() {
        pageState = PageState.ready();
      });
    } catch (e) {
      setState(() {
        pageState = PageState.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OpenTonic"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final changed =
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  ) ??
                  false;

              if (changed) {
                refreshLists();
              }
            },
          ),
        ],
      ),
      body: () {
        if (pageState.isLoading()) {
          return const Center(child: CircularProgressIndicator());
        } else if (pageState.isError()) {
          return Center(
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
          );
        }

        var listItems = lists.map((list) {
          return Card(
            child: ListTile(
              title: Text(list.name),
              subtitle: Text(list.owner),
              leading: Icon(Icons.storefront),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListPage(listId: list.id),
                  ),
                );
              },
            ),
          );
        }).toList();
        return RefreshIndicator(
          onRefresh: () async {
            refreshLists();
          },
          child: ListView(children: listItems),
        );
      }(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final changed =
              await showDialog(
                context: context,
                builder: (context) => AddListPage(),
              ) ??
              false;
          if (changed) refreshLists();
        },
      ),
    );
  }
}
