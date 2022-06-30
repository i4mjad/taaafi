import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/content_bloc.dart';
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
                      child: FutureBuilder(
                        future: bloc.getArticles(),
                        initialData: [],
                        builder: (BuildContext context, snapshot) {
                          switch (snapshot.connectionState) {
                            // Uncompleted State
                            case ConnectionState.none:
                            case ConnectionState.waiting:
                              return Center(child: CircularProgressIndicator());
                              break;
                            default:
                              // Completed with error
                              if (snapshot.hasError)
                                return Container(
                                  child: Center(
                                    child: Text(
                                      snapshot.error.toString(),
                                    ),
                                  ),
                                );

                              return ExploreListView(
                                  theme: theme, snapshot: snapshot);
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

class ExploreListView extends StatelessWidget {
  const ExploreListView({
    Key key,
    @required this.theme,
    @required this.snapshot,
  }) : super(key: key);

  final ThemeData theme;
  final AsyncSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ArticlePage(
                          article: snapshot.data[index],
                        ),
                ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.35,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border.all(color: theme.primaryColor, width: 0.25),
              borderRadius: BorderRadius.circular(12.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.backgroundColor,
                  child: Icon(
                    Iconsax.book,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ),
                Spacer(),
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          snapshot.data[index].title,
                          style: kSubTitlesSubsStyle.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
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
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(width: 16);
      },
    );
  }
}
