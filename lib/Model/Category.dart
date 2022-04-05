import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/Shared/Constants.dart';

class Category {
  Category(
      {this.categoryName,
      this.categoryIllustration,
      this.backgroundColor,
      this.categoryIcon,
      this.categoryDescribtion});

  String categoryName;
  String categoryDescribtion;
  String categoryIllustration;
  Color backgroundColor;
  var categoryIcon;
}

var categories = [
  Category(
      categoryName: "Articles",
      backgroundColor: primaryColor,
      categoryIllustration: 'asset/illustrations/articals.svg',
      categoryIcon:
          Platform.isIOS == true ? CupertinoIcons.news : Icons.article_outlined,
      categoryDescribtion: "Articles-Description"),
  Category(
      categoryName: "Videos",
      backgroundColor: primaryColor,
      categoryIllustration: 'asset/illustrations/videos.svg',
      categoryIcon: Platform.isIOS == true
          ? CupertinoIcons.play_circle
          : Icons.video_collection_outlined,
      categoryDescribtion: "Videos-Description"),
  Category(
      categoryName: "Blogs",
      backgroundColor: primaryColor,
      categoryIllustration: 'asset/illustrations/blogs.svg',
      categoryIcon: Platform.isIOS == true
          ? CupertinoIcons.pencil_circle
          : Icons.sticky_note_2_outlined,
      categoryDescribtion: "Blogs-Description"),
  Category(
      categoryName: "Books",
      backgroundColor: primaryColor,
      categoryIllustration: 'asset/illustrations/books.svg',
      categoryIcon:
          Platform.isIOS == true ? CupertinoIcons.book : Icons.book_outlined,
      categoryDescribtion: "Books-Description"),
];
