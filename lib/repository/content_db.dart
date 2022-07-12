import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/data/models/Article.dart';

class ContentDB {
  final firebaseDB = FirebaseFirestore.instance;

  Stream<QuerySnapshot> initStream() {
    return firebaseDB.collection("fl_content").snapshots();
  }

  Future<List<Article>> getArticlesList() async {
    final featured = await firebaseDB
        .collection("fl_content")
        .where("isFeatured" == true)
        .get();

    return featured.docs.map((e) => Article.fromMap(e)).toList();
  }

  Stream<QuerySnapshot> getFeaturedArticles() {
    return firebaseDB
        .collection("fl_content")
        .where("isFeatured", isEqualTo: true)
        .snapshots();
  }
}

ContentDB contentDb = ContentDB();
