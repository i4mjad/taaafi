// To parse this JSON data, do
//
//     final appContentServices = appContentServicesFromJson(jsonString);

import 'dart:convert';
import 'package:http/http.dart' as http;

AppContentServices appContentServicesFromJson(String str) =>
    AppContentServices.fromJson(json.decode(str));

String appContentServicesToJson(AppContentServices data) =>
    json.encode(data.toJson());

class AppContentServices {
  AppContentServices({
    this.items,
  });
  List<Item> items;

  factory AppContentServices.fromJson(Map<String, dynamic> json) =>
      AppContentServices(
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Item {
  Item({
    this.content,
  });

  Content content;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        content: Content.fromJson(json["fields"]),
      );

  Map<String, dynamic> toJson() => {
        "fields": content.toJson(),
      };
}

class Content {
  Content({
    this.title,
    this.contentOwner,
    this.contentLink,
    this.contentType,
    this.contentSubType,
    this.contentLanguage,
  });

  String title;
  String contentOwner;
  String contentLink;
  String contentType;
  String contentSubType;
  String contentLanguage;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        title: json["title"],
        contentOwner: json["contentOwner"],
        contentLink: json["contentLink"],
        contentType: json["contentType"],
        contentSubType: json["contentSubType"],
        contentLanguage: json["contentLanguage"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "contentOwner": contentOwner,
        "contentLink": contentLink,
        "contentType": contentType,
        "contentSubType": contentSubType,
        "contentLanguage": contentLanguage,
      };
}

class ContentServices {
  static const String url =
      'https://cdn.contentful.com/spaces/en6d4vi2xrxv/environments/master/entries?access_token=eCbHvzJ8CvTMZncNMHOrXfnzK-OmjWhjIgjq__oeVgg&content_type=appContent&select=fields';
  static Future<List<Item>> getContent() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (200 == response.statusCode) {
        final List<Item> users =
            appContentServicesFromJson(response.body).items;
        return users;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}







// class BlogServices {
//   static const String url = 'https://www.ta3afiapp.com/api/blog-data';

//   static Future<List<BlogPost>> getBlogPosts() async {
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         List<BlogPost> list = parseBlogPosts(response.body);
//         return list;
//       } else {
//         throw Exception("Error");
//       }
//     } catch (e) {
//       throw Exception(e.toString());
//     }
//   }

//   static List<BlogPost> parseBlogPosts(String responseBody) {
//     final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
//     return parsed.map<BlogPost>((json) => BlogPost.fromJson(json)).toList();
//   }
// }




