import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/data/models/Article.dart';

class ContentDB {
  final firebaseDB = FirebaseFirestore.instance;

  Stream<QuerySnapshot> initStream() {
    return firebaseDB.collection("fl_content").snapshots();
  }

  Future<List<ExploreContent>> getArticlesList() async {
    final featured = await firebaseDB
        .collection("fl_content")
        .where("isFeatured" == true)
        .get();

    return featured.docs.map((e) => ExploreContent.fromMap(e)).toList();
  }

  Stream<QuerySnapshot> getFeaturedArticles() {
    return firebaseDB
        .collection("fl_content")
        .where("isFeatured", isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Object>> getAllArticles() {
    return firebaseDB
        .collection("fl_content")
        .where("type", isEqualTo: "article")
        .snapshots();
  }

  Stream<QuerySnapshot<Object>> getAllTutorials() {
    return firebaseDB
        .collection("fl_content")
        .where("type", isEqualTo: "tutorial")
        .snapshots();
  }
}

ContentDB contentDb = ContentDB();
