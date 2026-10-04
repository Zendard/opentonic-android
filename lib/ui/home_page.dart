import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:opentonic/net.dart';
import 'package:opentonic/ui/add_list_page.dart';
import 'package:opentonic/ui/list_page.dart';
import 'package:opentonic/ui/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with OpenTonicPageState {
  late OpenTonicAPI openTonicAPI;
  late List<OpenTonicList> lists;
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
  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("OpenTonic"),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () async {
            final changed =
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ) ??
                false;

            if (changed) {
              refreshLists();
            }
          },
        ),
      ],
    );
  }

  @override
  Widget buildReady(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: () {
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
