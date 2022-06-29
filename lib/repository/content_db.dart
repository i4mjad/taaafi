import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/data/models/Article.dart';

class ContentDB {
  final firebaseDB = FirebaseFirestore.instance;

  Stream<QuerySnapshot> initStream() {
    return firebaseDB.collection("fl_content").snapshots();
  }

  Future<List<Article>> getArticlesList() async {
    var querySnapshot = await firebaseDB.collection("fl_content").get();

    return querySnapshot.docs.map((e) => Article.fromMap(e.data())).toList();
  }
}

ContentDB contentDb = ContentDB();
