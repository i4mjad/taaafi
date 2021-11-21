// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:reboot_app_3/Services/Constants.dart';

// class NoteScreen extends StatefulWidget {
//   NoteScreen({this.post});

//   final BlogPost post;

//   @override
//   _NoteScreenState createState() => _NoteScreenState();
// }

// class _NoteScreenState extends State<NoteScreen> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SafeArea(
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.only(left: 20.0, right: 20, top: 20),
//           child: Container(
//             width: MediaQuery.of(context).size.width - 40,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.pop(context);
//                       },
//                       child: Container(
//                         height: 40,
//                         width: 40,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(50),
//                           color: mainGrayColor,
//                         ),
//                         child: Icon(
//                           CupertinoIcons.arrow_left,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.pop(context);
//                       },
//                       child: Container(
//                         height: 40,
//                         width: 40,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(50),
//                           color: mainGrayColor,
//                         ),
//                         child: Icon(
//                           CupertinoIcons.xmark,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(
//                   height: 20,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Flexible(
//                       child: Text(
//                         "${widget.post.title}",
//                         style: kPageTitleStyle.copyWith(fontSize: 28),
//                         maxLines: 5,
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         print(
//                             "https://www.ta3afiapp.com/blog/${widget.post.slug}");
//                       },
//                       child: Container(
//                         height: 40,
//                         width: 40,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(50),
//                           color: primaryColor,
//                         ),
//                         child: Icon(
//                           Platform.isIOS == true
//                               ? CupertinoIcons.share
//                               : Icons.share,
//                           size: 20,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(
//                   height: 8,
//                 ),
//                 Expanded(
//                   child: Container(
//                     width: MediaQuery.of(context).size.width - 40,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [Text("Body")],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ));
//   }
// }
