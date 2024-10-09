export interface ContentType {
  id: string;
  contentTypeName: string;
  isActive: boolean;
}

export interface ContentTypeDataModel {
  contentTypeName: string;
  isActive: boolean;
}
export interface Content {
  id: string;
  contentName: string;
  contentType: ContentType;
  contentCategory: ContentCategory;
  contentOwner: ContentOwner;
  contentLink: string;
  createdAt: Date;
  updatedAt: Date;
  updatedBy: string; // user id
  isActive: boolean;
}
export interface ContentDateModel {
  contentName: string;
  contentTypeId: string;
  contentCategoryId: string;
  contentOwnerId: string;
  contentLink: string;
  createdAt?: Date;
  updatedAt?: Date;
  updatedBy?: string; // user id
  isActive: boolean;
}

export interface ContentCategory {
  id: string;
  categoryName: string;
  isActive: boolean;
}

export interface ContentCategoryDataModel {
  categoryName: string;
  isActive: boolean;
}

export interface ContentOwner {
  id: string;
  ownerName: string;
  ownerSource: string;
  isActive: boolean;
}

export interface ContentOwnerDataModel {
  ownerName: string;
  ownerSource: string;
  isActive: boolean;
}
