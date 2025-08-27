/// Enum for attachment types
enum AttachmentType {
  image,
  poll,
  groupInvite;

  @override
  String toString() {
    switch (this) {
      case AttachmentType.image:
        return 'image';
      case AttachmentType.poll:
        return 'poll';
      case AttachmentType.groupInvite:
        return 'group_invite';
    }
  }

  static AttachmentType fromString(String value) {
    switch (value) {
      case 'image':
        return AttachmentType.image;
      case 'poll':
        return AttachmentType.poll;
      case 'group_invite':
        return AttachmentType.groupInvite;
      default:
        throw ArgumentError('Unknown attachment type: $value');
    }
  }
}

/// Base class for attachment data
abstract class AttachmentData {
  final AttachmentType type;

  const AttachmentData(this.type);
}

/// Image attachment data for composer
class ImageAttachmentData extends AttachmentData {
  final List<ImageItem> images;

  const ImageAttachmentData({
    required this.images,
  }) : super(AttachmentType.image);

  ImageAttachmentData copyWith({
    List<ImageItem>? images,
  }) {
    return ImageAttachmentData(
      images: images ?? this.images,
    );
  }
}

/// Individual image item
class ImageItem {
  final String id;
  final String localPath;
  final String? fileName;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final String? thumbnailPath;

  const ImageItem({
    required this.id,
    required this.localPath,
    this.fileName,
    this.sizeBytes,
    this.width,
    this.height,
    this.thumbnailPath,
  });

  ImageItem copyWith({
    String? id,
    String? localPath,
    String? fileName,
    int? sizeBytes,
    int? width,
    int? height,
    String? thumbnailPath,
  }) {
    return ImageItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

/// Poll attachment data for composer
class PollAttachmentData extends AttachmentData {
  final String question;
  final List<PollOptionData> options;
  final bool isMultiSelect;
  final DateTime? closesAt;

  const PollAttachmentData({
    required this.question,
    required this.options,
    required this.isMultiSelect,
    this.closesAt,
  }) : super(AttachmentType.poll);

  PollAttachmentData copyWith({
    String? question,
    List<PollOptionData>? options,
    bool? isMultiSelect,
    DateTime? closesAt,
  }) {
    return PollAttachmentData(
      question: question ?? this.question,
      options: options ?? this.options,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      closesAt: closesAt ?? this.closesAt,
    );
  }

  bool get isValid {
    return question.trim().isNotEmpty &&
           question.length <= 100 &&
           options.length >= 2 &&
           options.length <= 4 &&
           options.every((option) => option.isValid);
  }
}

/// Individual poll option
class PollOptionData {
  final String id;
  final String text;

  const PollOptionData({
    required this.id,
    required this.text,
  });

  PollOptionData copyWith({
    String? id,
    String? text,
  }) {
    return PollOptionData(
      id: id ?? this.id,
      text: text ?? this.text,
    );
  }

  bool get isValid {
    return text.trim().isNotEmpty && text.length <= 100;
  }
}

/// Group invite attachment data for composer
class GroupInviteAttachmentData extends AttachmentData {
  final String groupId;
  final String groupName;
  final String groupGender;
  final int groupCapacity;
  final int groupMemberCount;
  final bool groupPlusOnly;
  final String joinMethod;

  const GroupInviteAttachmentData({
    required this.groupId,
    required this.groupName,
    required this.groupGender,
    required this.groupCapacity,
    required this.groupMemberCount,
    required this.groupPlusOnly,
    required this.joinMethod,
  }) : super(AttachmentType.groupInvite);

  GroupInviteAttachmentData copyWith({
    String? groupId,
    String? groupName,
    String? groupGender,
    int? groupCapacity,
    int? groupMemberCount,
    bool? groupPlusOnly,
    String? joinMethod,
  }) {
    return GroupInviteAttachmentData(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupGender: groupGender ?? this.groupGender,
      groupCapacity: groupCapacity ?? this.groupCapacity,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      groupPlusOnly: groupPlusOnly ?? this.groupPlusOnly,
      joinMethod: joinMethod ?? this.joinMethod,
    );
  }
}

/// State for post attachments in the composer
class PostAttachmentsState {
  final AttachmentType? selectedType;
  final AttachmentData? attachmentData;

  const PostAttachmentsState({
    this.selectedType,
    this.attachmentData,
  });

  PostAttachmentsState copyWith({
    AttachmentType? selectedType,
    AttachmentData? attachmentData,
  }) {
    return PostAttachmentsState(
      selectedType: selectedType,
      attachmentData: attachmentData,
    );
  }

  PostAttachmentsState clear() {
    return const PostAttachmentsState();
  }

  bool get hasAttachments => selectedType != null && attachmentData != null;
  
  bool get isValid {
    if (!hasAttachments) return true;
    
    switch (selectedType!) {
      case AttachmentType.image:
        final imageData = attachmentData as ImageAttachmentData;
        return imageData.images.isNotEmpty && imageData.images.length <= 4;
      case AttachmentType.poll:
        final pollData = attachmentData as PollAttachmentData;
        return pollData.isValid;
      case AttachmentType.groupInvite:
        return true; // Group invites are always valid once selected
    }
  }
}
