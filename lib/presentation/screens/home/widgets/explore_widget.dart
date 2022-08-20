import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/Article.dart';
import 'package:reboot_app_3/presentation/blocs/content_bloc.dart';
import 'package:reboot_app_3/presentation/screens/home/explore/explore_screen.dart';
import 'package:reboot_app_3/presentation/screens/home/widgets/article_screen.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class ExploreWidget extends StatelessWidget {
  const ExploreWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<ContentBloc>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).translate('explore'),
              style: kSubTitlesStyle.copyWith(color: theme.hintColor),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExploreScreen(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context).translate('show-all'),
                style: kSubTitlesStyle.copyWith(
                    color: theme.hintColor, fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 16,
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder(
                        stream: bloc.getFeaturedArticles(),
                        builder: (BuildContext context, snapshot) {
                          switch (snapshot.connectionState) {
                            // Uncompleted State
                            case ConnectionState.none:
                            case ConnectionState.waiting:
                              return Center(child: CircularProgressIndicator());
                              break;
                            default:
                              // Completed with error
                              if (snapshot.hasError) {
                                return Container(
                                  child: Center(
                                    child: Text(
                                      snapshot.error.toString(),
                                    ),
                                  ),
                                );
                              }

                              List<ExploreContent> featuredList = snapshot
                                  .data.docs
                                  .map<ExploreContent>(
                                      (e) => ExploreContent.fromMap(e))
                                  .toList();
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: featuredList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ExploreContentPage(
                                            article: featuredList[index],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      width: MediaQuery.of(context).size.width *
                                          0.35,
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius:
                                            BorderRadius.circular(12.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                theme.backgroundColor,
                                            child: Icon(
                                              Iconsax.book,
                                              size: 16,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Container(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    featuredList[index].title,
                                                    style: kSubTitlesSubsStyle
                                                        .copyWith(
                                                      color: theme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return SizedBox(width: 16);
                                },
                              );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
