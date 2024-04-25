import 'package:http/http.dart' as http;
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/models/Item.dart';
import 'app_content_service.dart';

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
