import { Injectable } from '@angular/core';
import { Action, Selector, State, StateContext } from '@ngxs/store';
import {
  CreateContentCategoryAction,
  CreateContentTypeAction,
  DeleteContentCategoryAction,
  DeleteContentTypeAction,
  GetContentCategoriesAction,
  GetContentTypesAction,
  ToggleContentCategoryStatusAction,
  ToggleContentTypeStatusAction,
  UpdateContentCategoryAction,
  UpdateContentTypeAction,
} from './app.actions';
import {
  ContentCategory,
  ContentCategoryDataModel,
  ContentType,
  ContentTypeDataModel,
} from '../models/app.model';
import { tap, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { ContentTypeService } from './services/content-type/content-type.service';
import { ContentCategoryService } from './services/content-category/content-category.service';

interface AppStateModel {
  contentTypes: ContentType[];
  contentCategories: ContentCategory[];
}

@State<AppStateModel>({
  name: 'taaafiControlPanel',
  defaults: {
    contentTypes: [],
    contentCategories: [],
  },
})
@Injectable()
export class AppState {
  @Selector()
  static contentTypes(state: AppStateModel): ContentType[] {
    return state.contentTypes;
  }

  @Selector()
  static contentCategories(state: AppStateModel): ContentCategory[] {
    return state.contentCategories;
  }

  constructor(
    private contentTypeService: ContentTypeService,
    private contentCategoryService: ContentCategoryService
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
}
