
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Action, Selector, State, StateContext } from '@ngxs/store';
import { GetContentTypesAction } from './app.actions';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { ContentType } from '../models/app.model';
import { map } from 'rxjs';

interface AppStateModel {
  contentTypes: string[];
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
  static contentTypes(state: AppStateModel): string[] {
    return state.contentTypes;
  }

  constructor(private firestore: AngularFirestore) {}


  @Action(GetContentTypesAction)
  getContentTypes(ctx: StateContext<AppStateModel>, action: GetContentTypesAction) {
    const collectionRef = this.firestore.collection<ContentType>('contentTypes');
    return collectionRef.valueChanges()
      .pipe(
        map((contentTypes: ContentType[]) => {
          const contentTypeNames = contentTypes.map(ct => ct.contentTypeName);
          ctx.patchState({ contentTypes: contentTypeNames });
        },)
      );
  }


}
