export interface ContentType {
  id: string;
  contentTypeName: string;
  isActive: boolean;
}

export interface ContentTypeDataModel {
  contentTypeName: string;
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
