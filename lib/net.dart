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

  Future<dynamic> _putRequest(String path, Object? body) async {
    final response = http.put(
      Uri.parse("$_serverUrl/api/$path"),
      headers: {
        HttpHeaders.authorizationHeader: "Basic $_authToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode(body),
    );
    return response;
  }

  Future<dynamic> _deleteRequest(String path) async {
    final response = http.delete(
      Uri.parse("$_serverUrl/api/$path"),
      headers: {HttpHeaders.authorizationHeader: "Basic $_authToken"},
    );
    return response;
  }

  Future<List<OpenTonicList>> getLists() async {
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

  Future<OpenTonicList> createList(String listName) async {
    final response = await _postRequest("lists", {"name": listName});

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicList.fromJson(json);
    } else {
      throw Exception(
        "Failed to create list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicList> getList(int listId) async {
    final response = await _getRequest("lists/$listId");

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return OpenTonicList.fromJson(json);
    } else {
      throw Exception(
        "Failed to fetch list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicList> updateList(
    int listId,
    String? listName,
    List<String>? users,
  ) async {
    final response = await _putRequest("lists/$listId", {
      "name": listName,
      "users": users,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicList.fromJson(json);
    } else {
      throw Exception(
        "Failed to update list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> deleteList(int listId) async {
    final response = await _deleteRequest("lists/$listId");

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to delete list: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<List<OpenTonicListItem>> getListItems(int listId) async {
    final response = await _getRequest("lists/$listId/items");

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicListItem.fromJson(str)).toList();
    } else {
      throw Exception(
        "Failed to fetch listItems: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicListItem> createListItem(
    int listId,
    String listItemName,
  ) async {
    final response = await _postRequest("lists/$listId/items", {
      "name": listItemName,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicListItem.fromJson(json);
    } else {
      throw Exception(
        "Failed to create list item: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicListItem> getListItem(int listId, int listItemId) async {
    final response = await _getRequest("lists/$listId/items/$listItemId");

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return OpenTonicListItem.fromJson(json);
    } else {
      throw Exception(
        "Failed to fetch listItem: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicListItem> updateListItem(
    int listId,
    int listItemId,
    bool checked,
  ) async {
    final response = await _putRequest("lists/$listId/items/$listItemId", {
      "checked": checked,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicListItem.fromJson(json);
    } else {
      throw Exception(
        "Failed to update listItem: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> deleteListItem(int listId, int listItemId) async {
    final response = await _deleteRequest("lists/$listId/items/$listItemId");

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to delete listItem: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<List<OpenTonicProduct>> queryProducts(int listId, String query) async {
    final response = await _getRequest("lists/$listId/products?q=$query");

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicProduct.fromJson(str)).toList();
    } else {
      throw Exception(
        "Failed to query products: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<List<OpenTonicProduct>> getProducts(int listId) async {
    final response = await _getRequest("lists/$listId/products");

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicProduct.fromJson(str)).toList();
    } else {
      throw Exception(
        "Failed to fetch products: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicProduct> getProduct(int listId, int productId) async {
    final response = await _getRequest("lists/$listId/products/$productId");

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return OpenTonicProduct.fromJson(json);
    } else {
      throw Exception(
        "Failed to fetch product: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicProduct> updateProduct(
    int listId,
    int productId,
    String? name,
    int? categoryId,
  ) async {
    final response = await _putRequest("lists/$listId/products/$productId", {
      "name": name,
      "category_id": categoryId,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicProduct.fromJson(json);
    } else {
      throw Exception(
        "Failed to update product: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> deleteProduct(int listId, int productId) async {
    final response = await _deleteRequest("lists/$listId/products/$productId");

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to delete product: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<List<OpenTonicCategory>> getCategories(int listId) async {
    final response = await _getRequest("lists/$listId/categories");

    if (response.statusCode == 200) {
      var strList = List.from(jsonDecode(response.body));
      return strList.map((str) => OpenTonicCategory.fromJson(str)).toList();
    } else {
      throw Exception(
        "Failed to fetch categories: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicCategory> getCategory(int listId, int categoryId) async {
    final response = await _getRequest("lists/$listId/categories/$categoryId");

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      return OpenTonicCategory.fromJson(json);
    } else {
      throw Exception(
        "Failed to fetch category: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicCategory> createCategory(
    int listId,
    String name,
    String? iconId,
  ) async {
    final response = await _postRequest("lists/$listId/categories", {
      "name": name,
      "icon_id": iconId,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicCategory.fromJson(json);
    } else {
      throw Exception(
        "Failed to create category: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<OpenTonicCategory> updateCategory(
    int listId,
    int categoryId,
    String? name,
    String? iconId,
    int? orderIndex,
  ) async {
    final response = await _putRequest("lists/$listId/categories/$categoryId", {
      "name": name,
      "icon_id": iconId,
      "order_index": orderIndex,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OpenTonicCategory.fromJson(json);
    } else {
      throw Exception(
        "Failed to update category: ${response.statusCode}, ${response.body}",
      );
    }
  }

  Future<int> deleteCategory(int listId, int categoryId) async {
    final response = await _deleteRequest(
      "lists/$listId/categories/$categoryId",
    );

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception(
        "Failed to delete category: ${response.statusCode}, ${response.body}",
      );
    }
  }
}
