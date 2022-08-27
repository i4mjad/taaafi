import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/repository/content_db.dart';
import 'package:rxdart/subjects.dart';

class ContentBloc implements CustomBlocBase {
  ContentBloc() {
    contentDb.initStream().listen((data) => _inFirestore.add(data));
  }

  final _firestoreController = BehaviorSubject<QuerySnapshot>();
  Stream<QuerySnapshot> get outFirestore => _firestoreController.stream;
  Sink<QuerySnapshot> get _inFirestore => _firestoreController.sink;

  Stream<QuerySnapshot> getFeaturedArticles() {
    return contentDb.getFeaturedArticles();
  }

  Stream<QuerySnapshot> getAllArticles() {
    return contentDb.getAllArticles();
  }

  @override
  void dispose() async {
    return _firestoreController.close();
  }
}
