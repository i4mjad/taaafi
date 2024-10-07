import { Injectable } from '@angular/core';
import { Action, Selector, State, StateContext } from '@ngxs/store';
import {
  CreateContentTypeAction,
  DeleteContentTypeAction,
  GetContentTypesAction,
  ToggleContentTypeStatusAction,
  UpdateContentTypeAction,
} from './app.actions';
import { ContentType, ContentTypeDataModel } from '../models/app.model';
import { tap, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { ContentTypeService } from './services/content-type/content-type.service';

interface AppStateModel {
  contentTypes: ContentType[];
}

@State<AppStateModel>({
  name: 'taaafiControlPanel',
  defaults: {
    contentTypes: [],
  },
})
@Injectable()
export class AppState {
  @Selector()
  static contentTypes(state: AppStateModel): ContentType[] {
    return state.contentTypes;
  }

  constructor(private contentTypeService: ContentTypeService) {}

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
