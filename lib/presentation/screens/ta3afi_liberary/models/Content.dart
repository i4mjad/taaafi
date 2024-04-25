class Content {
  Content({
    this.title,
    this.contentOwner,
    this.contentLink,
    this.contentType,
    this.contentSubType,
    this.contentLanguage,
  });

  String? title;
  String? contentOwner;
  String? contentLink;
  String? contentType;
  String? contentSubType;
  String? contentLanguage;

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        title: json["title"],
        contentOwner: json["contentOwner"],
        contentLink: json["contentLink"],
        contentType: json["contentType"],
        contentSubType: json["contentSubType"],
        contentLanguage: json["contentLanguage"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "contentOwner": contentOwner,
        "contentLink": contentLink,
        "contentType": contentType,
        "contentSubType": contentSubType,
        "contentLanguage": contentLanguage,
      };
}
