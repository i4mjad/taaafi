// Content module types for Ta'aafi Platform
export interface ContentType {
  id: string;
  contentTypeIconName: string;
  contentTypeName: string;
  contentTypeNameAr?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface ContentOwner {
  id: string;
  ownerName: string;
  ownerNameAr?: string;
  ownerSource: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Category {
  id: string;
  contentCategoryIconName: string;
  categoryName: string;
  categoryNameAr?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Content {
  id: string;
  contentName: string;
  contentNameAr?: string;
  contentLanguage: 'en' | 'ar' | 'both';
  contentLink: string;
  contentCategoryId: string;
  contentTypeId: string;
  contentOwnerId: string;
  isActive: boolean;
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface ContentList {
  id: string;
  listName: string;
  listNameAr?: string;
  listDescription: string;
  listDescriptionAr?: string;
  contentListIconName: string;
  listContentIds: string[];
  isFeatured: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Form types
export interface CreateContentTypeRequest {
  contentTypeIconName: string;
  contentTypeName: string;
  contentTypeNameAr?: string;
  isActive: boolean;
}

export interface UpdateContentTypeRequest {
  contentTypeIconName?: string;
  contentTypeName?: string;
  contentTypeNameAr?: string;
  isActive?: boolean;
}

export interface CreateContentOwnerRequest {
  ownerName: string;
  ownerNameAr?: string;
  ownerSource: string;
  isActive: boolean;
}

export interface UpdateContentOwnerRequest {
  ownerName?: string;
  ownerNameAr?: string;
  ownerSource?: string;
  isActive?: boolean;
}

export interface CreateCategoryRequest {
  contentCategoryIconName: string;
  categoryName: string;
  categoryNameAr?: string;
  isActive: boolean;
}

export interface UpdateCategoryRequest {
  contentCategoryIconName?: string;
  categoryName?: string;
  categoryNameAr?: string;
  isActive?: boolean;
}

export interface CreateContentRequest {
  contentName: string;
  contentNameAr?: string;
  contentLanguage: 'en' | 'ar' | 'both';
  contentLink: string;
  contentCategoryId: string;
  contentTypeId: string;
  contentOwnerId: string;
  isActive: boolean;
}

export interface UpdateContentRequest {
  contentName?: string;
  contentNameAr?: string;
  contentLanguage?: 'en' | 'ar' | 'both';
  contentLink?: string;
  contentCategoryId?: string;
  contentTypeId?: string;
  contentOwnerId?: string;
  isActive?: boolean;
  isDeleted?: boolean;
}

export interface CreateContentListRequest {
  listName: string;
  listNameAr?: string;
  listDescription: string;
  listDescriptionAr?: string;
  contentListIconName: string;
  listContentIds: string[];
  isFeatured: boolean;
  isActive: boolean;
}

export interface UpdateContentListRequest {
  listName?: string;
  listNameAr?: string;
  listDescription?: string;
  listDescriptionAr?: string;
  contentListIconName?: string;
  listContentIds?: string[];
  isFeatured?: boolean;
  isActive?: boolean;
}

// Filters
export interface ContentFilters {
  search?: string;
  isActive?: boolean;
  categoryId?: string;
  typeId?: string;
  ownerId?: string;
  language?: 'en' | 'ar' | 'both';
}

export interface ContentListFilters {
  search?: string;
  isActive?: boolean;
  isFeatured?: boolean;
}

// Component props
export interface ContentFormProps {
  content?: Content;
  onSubmit: (data: CreateContentRequest | UpdateContentRequest) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  t: (key: string) => string;
  locale: string;
}

export interface ContentTypeFormProps {
  contentType?: ContentType;
  onSubmit: (data: CreateContentTypeRequest | UpdateContentTypeRequest) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  t: (key: string) => string;
  locale: string;
}

export interface ContentOwnerFormProps {
  contentOwner?: ContentOwner;
  onSubmit: (data: CreateContentOwnerRequest | UpdateContentOwnerRequest) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  t: (key: string) => string;
  locale: string;
}

export interface CategoryFormProps {
  category?: Category;
  onSubmit: (data: CreateCategoryRequest | UpdateCategoryRequest) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  t: (key: string) => string;
  locale: string;
}

export interface ContentListFormProps {
  contentList?: ContentList;
  onSubmit: (data: CreateContentListRequest | UpdateContentListRequest) => Promise<void>;
  onCancel: () => void;
  isLoading?: boolean;
  t: (key: string) => string;
  locale: string;
} 