import {
  Content,
  ContentCategory,
  ContentOwner,
  ContentType,
} from '../models/app.model';

export class GetContentsAction {
  static readonly type = '[TaaafiControlPanel] Get Contents Action';
}

export class ToggleContentStatusAction {
  static readonly type = '[TaaafiControlPanel] Toggle Content Status Action';
  constructor(public id: string) {}
}

export class CreateContentAction {
  static readonly type = '[TaaafiControlPanel] Create Content Action';
  constructor(
    public contentName: string,
    public contentTypeId: string,
    public contentCategoryId: string,
    public contentOwnerId: string,
    public contentLink: string,
    public updatedBy: string, // user id
    public isActive: boolean
  ) {}
}

export class UpdateContentAction {
  static readonly type = '[TaaafiControlPanel] Edit Content Action';
  constructor(public content: Content) {}
}

export class DeleteContentAction {
  static readonly type = '[TaaafiControlPanel] Delete Content Action';
  constructor(public id: string) {}
}

export class GetContentTypesAction {
  static readonly type = '[TaaafiControlPanel] Get Content Types Action';
}

export class ToggleContentTypeStatusAction {
  static readonly type =
    '[TaaafiControlPanel] Toggle Content Type Status Action';

  constructor(public id: string) {}
}

export class CreateContentTypeAction {
  static readonly type = '[TaaafiControlPanel] Create Content Type Action';
  constructor(public contentTypeName: string, public isActive: boolean) {}
}

export class UpdateContentTypeAction {
  static readonly type = '[TaaafiControlPanel] Edit Content Type Action';
  constructor(public contentType: ContentType) {}
}

export class DeleteContentTypeAction {
  static readonly type = '[TaaafiControlPanel] Delete Content Type Action';
  constructor(public id: string) {}
}

export class GetContentCategoriesAction {
  static readonly type = '[TaaafiControlPanel] Get Content Categories Action';
}

export class ToggleContentCategoryStatusAction {
  static readonly type =
    '[TaaafiControlPanel] Toggle Content Category Status Action';

  constructor(public id: string) {}
}

export class CreateContentCategoryAction {
  static readonly type = '[TaaafiControlPanel] Create Content Category Action';
  constructor(public categoryName: string, public isActive: boolean) {}
}

export class UpdateContentCategoryAction {
  static readonly type = '[TaaafiControlPanel] Edit Content Category Action';
  constructor(public contentCategory: ContentCategory) {}
}

export class DeleteContentCategoryAction {
  static readonly type = '[TaaafiControlPanel] Delete Content Category Action';
  constructor(public id: string) {}
}

export class GetContentOwnersAction {
  static readonly type = '[TaaafiControlPanel] Get Content Owners Action';
}

export class CreateContentOwnerAction {
  static readonly type = '[TaaafiControlPanel] Create Content Owner Action';
  constructor(
    public ownerName: string,
    public ownerSource: string,
    public isActive: boolean
  ) {}
}

export class UpdateContentOwnerAction {
  static readonly type = '[TaaafiControlPanel] Update Content Owner Action';
  constructor(public contentOwner: ContentOwner) {}
}

export class DeleteContentOwnerAction {
  static readonly type = '[TaaafiControlPanel] Delete Content Owner Action';
  constructor(public id: string) {}
}

export class ToggleContentOwnerStatusAction {
  static readonly type =
    '[TaaafiControlPanel] Toggle Content Owner Status Action';

  constructor(public id: string) {}
}
