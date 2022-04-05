import 'package:flutter/material.dart';
import 'package:reboot_app_3/Shared/Constants.dart';

class ContentPost {
  ContentPost({
    this.postTitle,
    this.postCategory,
    this.backgroundColor,
    this.illustrationBackgroundColor,
    this.illustration,
    this.postContent,
    this.postLink,
  });

  String postTitle;
  String postCategory;
  Color illustrationBackgroundColor;
  Color backgroundColor;
  String illustration;
  String postContent;
  String postLink;
}

var recentPosts = [
  ContentPost(
    postTitle: "How to Start?",
    postCategory: "Guide",
    backgroundColor: mainGrayColor,
    illustrationBackgroundColor: primaryColor,
    illustration: 'Beginnings.png',
    postContent:
        '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."',
    postLink: 'http://bit.ly/3qZLDh2',
  ),
  ContentPost(
    postTitle: "Challenges",
    postCategory: "Guide1",
    backgroundColor: mainGrayColor,
    illustrationBackgroundColor: primaryColor,
    illustration: 'Challenges.png',
    postContent:
        'هذه هي أم مرحلة وهي التعرف على مضار هذا الكوكايين البصري الذي ينتشر ',
    postLink: 'http://bit.ly/3qZLDh2',
  ),
  ContentPost(
    postTitle: "Awards",
    postCategory: "Guide2",
    backgroundColor: mainGrayColor,
    illustrationBackgroundColor: primaryColor,
    illustration: 'Awards.png',
    postContent:
        'هذه هي أم مرحلة وهي التعرف على مضار هذا الكوكايين البصري الذي ينتشر بين الشباب بشكل كبير جدًا، فالاعتراف بالمشكلة ووجودها والتعرف على مضارها هو أمر مهم جدًا',
    postLink: 'http://bit.ly/3qZLDh2',
  ),
];
