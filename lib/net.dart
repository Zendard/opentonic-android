import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class OpenTonicAPI {
  final String _serverUrl;
  late String _authToken;
  final String username;

  OpenTonicAPI(this._serverUrl, this.username, String password) {
    _authToken = base64UrlEncode(utf8.encode("$username:$password"));
  }
  static Future<OpenTonicAPI> fromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString("server-url")!;
    final username = prefs.getString("username")!;
    final password = prefs.getString("password")!;
    return OpenTonicAPI(serverUrl, username, password);
  }

  Future<dynamic> _getRequest(String path) async {
    final response = http.get(
      Uri.parse("$_serverUrl/api/$path"),
      headers: {HttpHeaders.authorizationHeader: "Basic $_authToken"},
    );
    return response;
  }

  Future<dynamic> _postRequest(String path, Object? body) async {
    final response = http.post(
      Uri.parse("$_serverUrl/api/$path"),
      headers: {
        HttpHeaders.authorizationHeader: "Basic $_authToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode(body),
    );
    return response;
  }

  Future<List<OpenTonicList>> lists() async {
    final response = await _getRequest("lists");

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicList.fromJson(str)).toList();
    } else {
      throw Exception(
        "Failed to fetch lists: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> addList(String listName) async {
    final response = await _postRequest("create-list", {"name": listName});

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["id"];
    } else {
      throw Exception(
        "Failed to add list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicListFull> list(int id) async {
    final response = await _getRequest("/list/$id");

    if (response.statusCode == 200) {
      return OpenTonicListFull.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Failed to fetch list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<void> setChecked(int id, bool checked) async {
    final response = await _postRequest(
      "check-list-item/$id?checked=$checked",
      {},
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to check list item: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> deleteListItem(int id) async {
    final response = await _postRequest("delete-list-item/$id", {});

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to delete list item: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<String> addUserToList(int listId, String username) async {
    final response = await _postRequest("add-user-to-list/$listId", {
      "user": username,
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
        "Failed to add user: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> addListItem(int listId, String listItem) async {
    final response = await _postRequest("add-list-item/$listId", {
      "name": listItem,
    });

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to add list item: ${response.statusCode}, ${response.body}",
      );
    }
  }
}
