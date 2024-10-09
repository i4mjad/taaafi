import { Injectable } from '@angular/core';
import { Action, Selector, State, StateContext } from '@ngxs/store';
import {
  CreateContentAction,
  CreateContentCategoryAction,
  CreateContentOwnerAction,
  CreateContentTypeAction,
  DeleteContentAction,
  DeleteContentCategoryAction,
  DeleteContentOwnerAction,
  DeleteContentTypeAction,
  GetContentCategoriesAction,
  GetContentOwnersAction,
  GetContentsAction,
  GetContentTypesAction,
  ToggleContentCategoryStatusAction,
  ToggleContentOwnerStatusAction,
  ToggleContentStatusAction,
  ToggleContentTypeStatusAction,
  UpdateContentAction,
  UpdateContentCategoryAction,
  UpdateContentOwnerAction,
  UpdateContentTypeAction,
} from './app.actions';
import {
  Content,
  ContentCategory,
  ContentCategoryDataModel,
  ContentDateModel,
  ContentOwner,
  ContentOwnerDataModel,
  ContentType,
  ContentTypeDataModel,
} from '../models/app.model';
import { tap, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { ContentTypeService } from './services/content-type/content-type.service';
import { ContentCategoryService } from './services/content-category/content-category.service';
import { ContentOwnerService } from './services/content-owner/content-owner.service';
import { ContentService } from './services/content/content.service';

interface AppStateModel {
  contents: Content[];
  contentTypes: ContentType[];
  contentCategories: ContentCategory[];
  contentOwners: ContentOwner[];
}

@State<AppStateModel>({
  name: 'taaafiControlPanel',
  defaults: {
    contents: [],
    contentTypes: [],
    contentCategories: [],
    contentOwners: [],
  },
})
@Injectable()
export class AppState {
  @Selector()
  static content(state: AppStateModel): Content[] {
    return state.contents;
  }
  @Selector()
  static contentTypes(state: AppStateModel): ContentType[] {
    return state.contentTypes;
  }

  @Selector()
  static contentCategories(state: AppStateModel): ContentCategory[] {
    return state.contentCategories;
  }

  @Selector()
  static contentOwners(state: AppStateModel): ContentOwner[] {
    return state.contentOwners;
  }

  constructor(
    private contentTypeService: ContentTypeService,
    private contentCategoryService: ContentCategoryService,
    private contentOwnerService: ContentOwnerService,
    private contentService: ContentService
  ) {}

  @Action(GetContentCategoriesAction)
  getContentCategories(ctx: StateContext<AppStateModel>) {
    return this.contentCategoryService.getContentCategories().pipe(
      tap((contentCategories) => ctx.patchState({ contentCategories })),
      catchError((error) => {
        console.error('Error fetching content categories:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(ToggleContentCategoryStatusAction)
  toggleContentCategoryStatus(
    ctx: StateContext<AppStateModel>,
    action: ToggleContentCategoryStatusAction
  ) {
    return this.contentCategoryService
      .toggleContentCategoryStatus(action.id)
      .pipe(
        tap(() => {
          const contentCategories = ctx
            .getState()
            .contentCategories.map((category) => {
              if (category.id === action.id) {
                return { ...category, isActive: !category.isActive };
              }
              return category;
            });
          ctx.patchState({ contentCategories });
        }),
        catchError((error) => {
          console.error('Error toggling content category status:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(CreateContentCategoryAction)
  createContentCategory(
    ctx: StateContext<AppStateModel>,
    action: CreateContentCategoryAction
  ) {
    const newContentCategory: ContentCategoryDataModel = {
      categoryName: action.categoryName,
      isActive: action.isActive,
    };
    return this.contentCategoryService
      .createContentCategory(newContentCategory)
      .pipe(
        tap((createdContentCategory) => {
          const contentCategories = [
            ...ctx.getState().contentCategories,
            createdContentCategory,
          ];
          ctx.patchState({ contentCategories });
        }),
        catchError((error) => {
          console.error('Error creating content category:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(UpdateContentCategoryAction)
  updateContentCategory(
    ctx: StateContext<AppStateModel>,
    action: UpdateContentCategoryAction
  ) {
    return this.contentCategoryService
      .updateContentCategory(action.contentCategory)
      .pipe(
        tap(() => {
          const contentCategories = ctx
            .getState()
            .contentCategories.map((ct) =>
              ct.id === action.contentCategory.id ? action.contentCategory : ct
            );
          ctx.patchState({ contentCategories });
        }),
        catchError((error) => {
          console.error('Error updating content category:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(DeleteContentCategoryAction)
  deleteContentCategory(
    ctx: StateContext<AppStateModel>,
    action: DeleteContentCategoryAction
  ) {
    return this.contentCategoryService.deleteContentCategory(action.id).pipe(
      tap(() => {
        const contentCategories = ctx
          .getState()
          .contentCategories.filter((ct) => ct.id !== action.id);
        ctx.patchState({ contentCategories });
      }),
      catchError((error) => {
        console.error('Error deleting content category:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(GetContentTypesAction)
  getContentTypes(ctx: StateContext<AppStateModel>) {
    return this.contentTypeService.getContentTypes().pipe(
      tap((contentTypes) => ctx.patchState({ contentTypes })),
      catchError((error) => {
        console.error('Error fetching content types:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(ToggleContentTypeStatusAction)
  toggleContentTypeStatus(
    ctx: StateContext<AppStateModel>,
    action: ToggleContentTypeStatusAction
  ) {
    return this.contentTypeService.toggleContentTypeStatus(action.id).pipe(
      tap(() => {
        const contentTypes = ctx.getState().contentTypes.map((contentType) => {
          if (contentType.id === action.id) {
            return { ...contentType, isActive: !contentType.isActive };
          }
          return contentType;
        });
        ctx.patchState({ contentTypes });
      }),
      catchError((error) => {
        console.error('Error toggling content type status:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(CreateContentTypeAction)
  createContentType(
    ctx: StateContext<AppStateModel>,
    action: CreateContentTypeAction
  ) {
    const newContentType: ContentTypeDataModel = {
      contentTypeName: action.contentTypeName,
      isActive: action.isActive,
    };
    return this.contentTypeService.createContentType(newContentType).pipe(
      tap((createdContentType) => {
        const contentTypes = [
          ...ctx.getState().contentTypes,
          createdContentType,
        ];
        ctx.patchState({ contentTypes });
      }),
      catchError((error) => {
        console.error('Error creating content type:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(UpdateContentTypeAction)
  updateContentType(
    ctx: StateContext<AppStateModel>,
    action: UpdateContentTypeAction
  ) {
    return this.contentTypeService.updateContentType(action.contentType).pipe(
      tap(() => {
        const contentTypes = ctx
          .getState()
          .contentTypes.map((ct) =>
            ct.id === action.contentType.id ? action.contentType : ct
          );
        ctx.patchState({ contentTypes });
      }),
      catchError((error) => {
        console.error('Error updating content type:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(DeleteContentTypeAction)
  deleteContentType(
    ctx: StateContext<AppStateModel>,
    action: DeleteContentTypeAction
  ) {
    return this.contentTypeService.deleteContentType(action.id).pipe(
      tap(() => {
        const contentTypes = ctx
          .getState()
          .contentTypes.filter((ct) => ct.id !== action.id);
        ctx.patchState({ contentTypes });
      }),
      catchError((error) => {
        console.error('Error deleting content type:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(GetContentOwnersAction)
  getContentOwners(ctx: StateContext<AppStateModel>) {
    return this.contentOwnerService.getContentOwners().pipe(
      tap((contentOwners) => ctx.patchState({ contentOwners })),
      catchError((error) => {
        console.error('Error fetching content owners:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(CreateContentOwnerAction)
  createContentOwner(
    ctx: StateContext<AppStateModel>,
    action: CreateContentOwnerAction
  ) {
    const newContentOwner: ContentOwnerDataModel = {
      ownerName: action.ownerName,
      ownerSource: action.ownerSource,
      isActive: action.isActive,
    };
    return this.contentOwnerService.createContentOwner(newContentOwner).pipe(
      tap((createdContentOwner) => {
        const contentOwners = [
          ...ctx.getState().contentOwners,
          createdContentOwner,
        ];
        ctx.patchState({ contentOwners });
      }),
      catchError((error) => {
        console.error('Error creating content owner:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(UpdateContentOwnerAction)
  updateContentOwner(
    ctx: StateContext<AppStateModel>,
    action: UpdateContentOwnerAction
  ) {
    return this.contentOwnerService
      .updateContentOwner(action.contentOwner)
      .pipe(
        tap(() => {
          const contentOwners = ctx
            .getState()
            .contentOwners.map((owner) =>
              owner.id === action.contentOwner.id ? action.contentOwner : owner
            );
          ctx.patchState({ contentOwners });
        }),
        catchError((error) => {
          console.error('Error updating content owner:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(DeleteContentOwnerAction)
  deleteContentOwner(
    ctx: StateContext<AppStateModel>,
    action: DeleteContentOwnerAction
  ) {
    return this.contentOwnerService.deleteContentOwner(action.id).pipe(
      tap(() => {
        const contentOwners = ctx
          .getState()
          .contentOwners.filter((owner) => owner.id !== action.id);
        ctx.patchState({ contentOwners });
      }),
      catchError((error) => {
        console.error('Error deleting content owner:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(ToggleContentOwnerStatusAction)
  toggleContentOwnerStatus(
    ctx: StateContext<AppStateModel>,
    action: ToggleContentOwnerStatusAction
  ) {
    return this.contentOwnerService.toggleContentOwnerStatus(action.id).pipe(
      tap(() => {
        const contentOwners = ctx.getState().contentOwners.map((owner) => {
          if (owner.id === action.id) {
            return { ...owner, isActive: !owner.isActive };
          }
          return owner;
        });
        ctx.patchState({ contentOwners });
      }),
      catchError((error) => {
        console.error('Error toggling content category status:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(GetContentsAction)
  getContents(ctx: StateContext<AppStateModel>) {
    return this.contentService.getContents().pipe(
      tap((contents) => {
        console.log(contents);

        ctx.patchState({ contents });
      }),
      catchError((error) => {
        console.error('Error fetching contents:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(ToggleContentStatusAction)
  toggleContentStatus(
    ctx: StateContext<AppStateModel>,
    action: ToggleContentStatusAction
  ) {
    return this.contentService.toggleContentStatus(action.id).pipe(
      tap(() => {
        const contents = ctx.getState().contents.map((content) => {
          if (content.id === action.id) {
            return { ...content, isActive: !content.isActive };
          }
          return content;
        });
        ctx.patchState({ contents });
      }),
      catchError((error) => {
        console.error('Error toggling content status:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(CreateContentAction)
  createContent(ctx: StateContext<AppStateModel>, action: CreateContentAction) {
    const newContent: ContentDateModel = {
      contentName: action.contentName,
      contentTypeId: action.contentTypeId,
      contentCategoryId: action.contentCategoryId,
      contentOwnerId: action.contentOwnerId,
      contentLink: action.contentLink,
      createdAt: new Date(),
      updatedAt: new Date(),
      updatedBy: action.updatedBy,
      isActive: action.isActive,
    };

    return this.contentService.createContent(newContent).pipe(
      tap((fullContent) => {
        // Full content with related details
        const contents = [...ctx.getState().contents, fullContent];
        ctx.patchState({ contents });
      }),
      catchError((error) => {
        console.error('Error creating content:', error);
        return throwError(() => error);
      })
    );
  }

  @Action(UpdateContentAction)
  updateContent(ctx: StateContext<AppStateModel>, action: UpdateContentAction) {
    return this.contentService
      .updateContent(action.contentId, action.contentData)
      .pipe(
        tap(() => {
          const contents = ctx
            .getState()
            .contents.map((content) =>
              content.id === action.contentId
                ? { ...content, ...action.contentData }
                : content
            );
          ctx.patchState({ contents });
        }),
        catchError((error) => {
          console.error('Error updating content:', error);
          return throwError(() => error);
        })
      );
  }

  @Action(DeleteContentAction)
  deleteContent(ctx: StateContext<AppStateModel>, action: DeleteContentAction) {
    return this.contentService.deleteContent(action.id).pipe(
      tap(() => {
        const contents = ctx
          .getState()
          .contents.filter((ct) => ct.id !== action.id);
        ctx.patchState({ contents });
      }),
      catchError((error) => {
        console.error('Error deleting content:', error);
        return throwError(() => error);
      })
    );
  }
}
