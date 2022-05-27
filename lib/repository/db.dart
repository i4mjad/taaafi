import 'package:cloud_firestore/cloud_firestore.dart';

class DB {
  final db = FirebaseFirestore.instance;
}

DB db = DB();
