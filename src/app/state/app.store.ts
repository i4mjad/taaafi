import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Action, Selector, State, StateContext } from '@ngxs/store';
import {
  CreateContentTypeAction,
  DeleteContentTypeAction,
  GetContentTypesAction,
  ToggleContentTypeStatusAction,
  UpdateContentTypeAction,
} from './app.actions';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { ContentType, ContentTypeDataModel } from '../models/app.model';
import { map, switchMap, throwError } from 'rxjs';

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

  constructor(private firestore: AngularFirestore) {}

  @Action(GetContentTypesAction)
  getContentTypes(
    ctx: StateContext<AppStateModel>,
    action: GetContentTypesAction
  ) {
    const collectionRef =
      this.firestore.collection<ContentType>('contentTypes');
    return collectionRef.snapshotChanges().pipe(
      map((actions) => {
        const contentTypes = actions.map((a) => {
          const data = a.payload.doc.data() as Omit<ContentType, 'id'>; // Omit 'id' from the type
          const id = a.payload.doc.id; // Extract document ID
          return { id, ...data };
        });
        ctx.patchState({ contentTypes: contentTypes });
      })
    );
  }

  @Action(ToggleContentTypeStatusAction)
  toggleContentTypeStatus(
    ctx: StateContext<AppStateModel>,
    action: ToggleContentTypeStatusAction
  ) {
    const collectionRef =
      this.firestore.collection<ContentType>('contentTypes');
    const docRef = collectionRef.doc(action.id); // Get the document reference using the ID passed in the action

    return docRef.get().pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentType;
          const newStatus = !currentData.isActive; // Toggle the boolean field `status`

          // Update the Firestore document with the toggled status
          return docRef.update({ isActive: newStatus }).then(() => {
            // Optionally update the state in NGXS after the document is successfully updated
            const contentTypes = ctx
              .getState()
              .contentTypes.map((contentType) =>
                contentType.id === action.id
                  ? { ...contentType, status: newStatus }
                  : contentType
              );
            ctx.patchState({ contentTypes: contentTypes });
          });
        } else {
          throw new Error('Document does not exist');
        }
      })
    );
  }

  @Action(CreateContentTypeAction)
  createContentType(
    ctx: StateContext<AppStateModel>,
    action: CreateContentTypeAction
  ) {
    const collectionRef =
      this.firestore.collection<ContentTypeDataModel>('contentTypes');

    const newContentType: ContentTypeDataModel = {
      contentTypeName: action.contentTypeName,
      isActive: action.isActive,
    };

    return collectionRef.add(newContentType).then((docRef) => {
      const createdContentType: ContentType = {
        id: docRef.id,
        contentTypeName: action.contentTypeName,
        isActive: action.isActive,
      };

      const contentTypes = ctx.getState().contentTypes;
      ctx.patchState({ contentTypes: [...contentTypes, createdContentType] });
    });
  }

  @Action(UpdateContentTypeAction)
  updateContentType(
    ctx: StateContext<AppStateModel>,
    action: UpdateContentTypeAction
  ) {
    const contentType = action.contentType;
    const collectionRef = this.firestore.collection('contentTypes');

    // Get the document reference using the id and update it
    return collectionRef
      .doc(contentType.id)
      .update({
        contentTypeName: contentType.contentTypeName,
        isActive: contentType.isActive,
      })
      .then(() => {
        // Update the local state after successfully updating Firestore
        const contentTypes = ctx
          .getState()
          .contentTypes.map((ct) =>
            ct.id === contentType.id ? contentType : ct
          );
        ctx.patchState({ contentTypes: contentTypes });
      })
      .catch((error) => {
        // Handle any errors
        console.error('Error updating content type: ', error);
        return throwError(error);
      });
  }

  @Action(DeleteContentTypeAction)
  deleteContentType(
    ctx: StateContext<AppStateModel>,
    action: DeleteContentTypeAction
  ) {
    const collectionRef = this.firestore.collection('contentTypes');

    // Delete the document from Firestore using its ID
    return collectionRef
      .doc(action.id)
      .delete()
      .then(() => {
        // Update the local state after successful deletion
        const contentTypes = ctx
          .getState()
          .contentTypes.filter((contentType) => contentType.id !== action.id);
        ctx.patchState({ contentTypes: contentTypes });
      })
      .catch((error) => {
        // Handle any errors
        console.error('Error deleting content type: ', error);
        return throwError(error);
      });
  }
}
