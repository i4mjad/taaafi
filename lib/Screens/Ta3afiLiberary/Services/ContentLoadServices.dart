import 'package:http/http.dart' as http;
import 'package:reboot_app_3/Screens/Ta3afiLiberary/Models/Item.dart';

import 'AppContentService.dart';

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




