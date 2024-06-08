import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/Article.dart';

import 'package:reboot_app_3/presentation/blocs/content_bloc.dart';

import 'package:reboot_app_3/presentation/screens/home/widgets/article_screen.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: appBarWithSettings(context, "explore"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20, top: 20),
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate("articles"),
                  style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
                ),
                SizedBox(
                  height: 18,
                ),
                CustomBlocProvider(
                  child: ArticlesListView(),
                  bloc: ContentBloc(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArticlesListView extends StatelessWidget {
  ArticlesListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<ContentBloc>(context);
    return StreamBuilder(
      stream: bloc.getAllArticles(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        switch (snapshot.connectionState) {
          // Uncompleted State
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());

          default:
            // Completed with error
            if (snapshot.hasError || !snapshot.hasData) {
              return Container(
                child: Center(
                  child: Text(
                    snapshot.error.toString(),
                  ),
                ),
              );
            }

            var featuredList = snapshot.data?.docs
                .map<ExploreContent>((e) => ExploreContent.fromMap(e))
                .toList();
            return Expanded(
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: featuredList?.length as int,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExploreContentPage(
                            article: featuredList?[index] as ExploreContent,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12.5),
                                ),
                                child: Center(
                                  child: Icon(
                                    Iconsax.book,
                                    size: 16,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Flexible(
                                child: Text(
                                  featuredList?[index].title as String,
                                  style: kSubTitlesStyle.copyWith(
                                      color: theme.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.paperclip_2,
                                size: 14,
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                AppLocalizations.of(context).translate(
                                    featuredList?[index].type as String),
                                style: kSubTitlesStyle.copyWith(
                                    color: theme.primaryColor, fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.calendar,
                                size: 14,
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy hh:mm').format(
                                    DateTime.parse(
                                        featuredList?[index].date as String)),
                                style: kSubTitlesStyle.copyWith(
                                    color: theme.primaryColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 16);
                },
              ),
            );
        }
      },
    );
  }
}
