import {
  Content,
  ContentCategory,
  ContentDateModel,
  ContentListDataModel,
  ContentOwner,
  ContentType,
} from '../../models/library.model';

export class GetContentsAction {
  static readonly type = '[Library] Get Contents Action';
}
export class GetActiveContentAction {
  static readonly type = '[Library] Get Active Contents Action';
}

export class ToggleContentStatusAction {
  static readonly type = '[Library] Toggle Content Status Action';
  constructor(public id: string) {}
}

export class CreateContentAction {
  static readonly type = '[Library] Create Content Action';
  constructor(
    public contentName: string,
    public contentTypeId: string,
    public contentCategoryId: string,
    public contentOwnerId: string,
    public contentLink: string,
    public contentLanguage: string,
    public updatedBy: string, // user id
    public isActive: boolean
  ) {}
}

export class UpdateContentAction {
  static readonly type = '[Library] Edit Content Action';
  constructor(public contentId: string, public contentData: ContentDateModel) {}
}

export class DeleteContentAction {
  static readonly type = '[Library] Delete Content Action';
  constructor(public id: string) {}
}

export class GetContentTypesAction {
  static readonly type = '[Library] Get Content Types Action';
}

export class ToggleContentTypeStatusAction {
  static readonly type = '[Library] Toggle Content Type Status Action';

  constructor(public id: string) {}
}

export class CreateContentTypeAction {
  static readonly type = '[Library] Create Content Type Action';
  constructor(public contentTypeName: string, public isActive: boolean) {}
}

export class UpdateContentTypeAction {
  static readonly type = '[Library] Edit Content Type Action';
  constructor(public contentType: ContentType) {}
}

export class DeleteContentTypeAction {
  static readonly type = '[Library] Delete Content Type Action';
  constructor(public id: string) {}
}

export class GetContentCategoriesAction {
  static readonly type = '[Library] Get Content Categories Action';
}

export class ToggleContentCategoryStatusAction {
  static readonly type = '[Library] Toggle Content Category Status Action';

  constructor(public id: string) {}
}

export class GetContentListByIdAction {
  static readonly type = '[Library] Get Content List By Id Action';

  constructor(public id: string) {}
}

export class CreateContentCategoryAction {
  static readonly type = '[Library] Create Content Category Action';
  constructor(public categoryName: string, public isActive: boolean) {}
}

export class UpdateContentCategoryAction {
  static readonly type = '[Library] Edit Content Category Action';
  constructor(public contentCategory: ContentCategory) {}
}

export class DeleteContentCategoryAction {
  static readonly type = '[Library] Delete Content Category Action';
  constructor(public id: string) {}
}

export class GetContentOwnersAction {
  static readonly type = '[Library] Get Content Owners Action';
}

export class CreateContentOwnerAction {
  static readonly type = '[Library] Create Content Owner Action';
  constructor(
    public ownerName: string,
    public ownerSource: string,
    public isActive: boolean
  ) {}
}

export class UpdateContentOwnerAction {
  static readonly type = '[Library] Update Content Owner Action';
  constructor(public contentOwner: ContentOwner) {}
}

export class DeleteContentOwnerAction {
  static readonly type = '[Library] Delete Content Owner Action';
  constructor(public id: string) {}
}

export class ToggleContentOwnerStatusAction {
  static readonly type = '[Library] Toggle Content Owner Status Action';

  constructor(public id: string) {}
}

export class GetContentListsAction {
  static readonly type = '[Library] Get Content Lists Action';
}

export class CreateContentListAction {
  static readonly type = '[Library] Create Content List Action';
  constructor(
    public listName: string,
    public listDescription: string,
    public listContentIds: string[],
    public isActive: boolean,
    public isFeatured: boolean
  ) {}
}

export class UpdateContentListAction {
  static readonly type = '[Library] Edit Content List Action';
  constructor(
    public id: string,
    public contentListData: ContentListDataModel
  ) {}
}

export class DeleteContentListAction {
  static readonly type = '[Library] Delete Content List Action';
  constructor(public id: string) {}
}

export class ToggleContentListStatusAction {
  static readonly type = '[Library] Toggle Content List Status Action';
  constructor(public id: string) {}
}

export class ToggleContentListFeaturedAction {
  static readonly type = '[Library] Toggle Content List Featured Status Action';
  constructor(public id: string) {}
}
