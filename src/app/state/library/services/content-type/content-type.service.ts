import { Injectable } from '@angular/core';
import {
  AngularFirestore,
  AngularFirestoreCollection,
} from '@angular/fire/compat/firestore';
import { Observable, from, throwError } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';
import {
  ContentType,
  ContentTypeDataModel,
} from '../../../../models/library.model';

@Injectable({
  providedIn: 'root',
})
export class ContentTypeService {
  private contentTypesCollectionsRef: AngularFirestoreCollection<ContentTypeDataModel>;

  constructor(private firestore: AngularFirestore) {
    this.contentTypesCollectionsRef =
      this.firestore.collection<ContentTypeDataModel>('contentTypes');
  }

  getContentTypes(): Observable<ContentType[]> {
    return this.contentTypesCollectionsRef.snapshotChanges().pipe(
      map((contentTypeDocuments) =>
        contentTypeDocuments.map((a) => {
          const data = a.payload.doc.data() as ContentTypeDataModel;
          const id = a.payload.doc.id;
          return { id, ...data } as ContentType;
        })
      )
    );
  }

  toggleContentTypeStatus(id: string): Observable<void> {
    const docRef = this.contentTypesCollectionsRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentTypeDataModel;
          const newStatus = !currentData.isActive;
          return from(docRef.update({ isActive: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  createContentType(
    contentType: ContentTypeDataModel
  ): Observable<ContentType> {
    return from(this.contentTypesCollectionsRef.add(contentType)).pipe(
      map((docRef) => ({ id: docRef.id, ...contentType } as ContentType))
    );
  }

  updateContentType(contentType: ContentType): Observable<void> {
    return from(
      this.contentTypesCollectionsRef.doc(contentType.id).update({
        contentTypeName: contentType.contentTypeName,
        isActive: contentType.isActive,
      })
    );
  }

  deleteContentType(id: string): Observable<void> {
    return from(this.contentTypesCollectionsRef.doc(id).delete());
  }
}
