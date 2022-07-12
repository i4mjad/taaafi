import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/data/models/Article.dart';

class ContentDB {
  final firebaseDB = FirebaseFirestore.instance;

  Stream<QuerySnapshot> initStream() {
    return firebaseDB.collection("fl_content").snapshots();
  }

  Future<List<Article>> getArticlesList() async {
    var querySnapshot = await firebaseDB.collection("fl_content").get();

    final citiesRef = firebaseDB.collection("cities").orderBy("field").limit(3);
    citiesRef.orderBy("name", descending: true).limit(3);
    return querySnapshot.docs.map((e) => Article.fromMap(e)).toList();
  }

  Stream<QuerySnapshot> getWelcomeArticles() {
    return initStream();
  }
}

ContentDB contentDb = ContentDB();
