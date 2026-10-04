import 'package:material_ui/material_ui.dart';
import 'package:opentonic/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with OpenTonicPageState {
  late SharedPreferences prefs;
  final serverUrlContoller = TextEditingController();
  final usernameContoller = TextEditingController();
  final passwordContoller = TextEditingController();
  var changed = false;
  var edited = false;

  @override
  void initState() {
    super.initState();

    () async {
      try {
        await loadPrefs();
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

  Future<void> loadPrefs() async {
    final prefsLocal = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefsLocal;
      serverUrlContoller.text = prefs.getString("server-url") ?? "";
      usernameContoller.text = prefs.getString("username") ?? "";
      passwordContoller.text = prefs.getString("password") ?? "";
    });
  }

  @override
  Widget buildReady(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
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
              Text("Server Settings", style: TextStyle(fontSize: 24)),
              Card.filled(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    spacing: 16,
                    children: [
                      TextField(
                        controller: serverUrlContoller,
                        decoration: InputDecoration(
                          labelText: "Server URL",
                          border: OutlineInputBorder(),
                          hintText: "https://server.example:port/subdirectory",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                        onSubmitted: (value) {
                          prefs.setString("server-url", value);
                        },
                        onChanged: (_) {
                          setState(() {
                            edited = true;
                          });
                        },
                      ),
                      TextField(
                        controller: usernameContoller,
                        decoration: InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(),
                          hintText: "admin",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.name,
                        onSubmitted: (value) {
                          prefs.setString("username", value);
                        },
                        onChanged: (_) {
                          setState(() {
                            edited = true;
                          });
                        },
                      ),
                      TextField(
                        controller: passwordContoller,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          hintText: "password",
                        ),
                        autocorrect: false,
                        keyboardType: TextInputType.text,
                        onSubmitted: (value) {
                          prefs.setString("password", value);
                        },
                        onChanged: (_) {
                          setState(() {
                            edited = true;
                          });
                        },
                      ),
                    ],
                  ),
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
            prefs.setString("server-url", serverUrlContoller.text);
            prefs.setString("username", usernameContoller.text);
            prefs.setString("password", passwordContoller.text);
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
