import { Injectable } from '@angular/core';
import {
  AngularFirestoreCollection,
  AngularFirestore,
} from '@angular/fire/compat/firestore';
import { Observable, map, from, switchMap, throwError } from 'rxjs';
import {
  ContentOwnerDataModel,
  ContentOwner,
} from '../../../../models/library.model';

@Injectable({
  providedIn: 'root',
})
export class ContentOwnerService {
  private contentOwnersCollectionRef: AngularFirestoreCollection<ContentOwnerDataModel>;

  constructor(private firestore: AngularFirestore) {
    this.contentOwnersCollectionRef =
      this.firestore.collection<ContentOwnerDataModel>('contentOwners');
  }

  toggleContentOwnerStatus(id: string): Observable<void> {
    const docRef = this.contentOwnersCollectionRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentOwnerDataModel;
          const newStatus = !currentData.isActive;
          return from(docRef.update({ isActive: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  getContentOwners(): Observable<ContentOwner[]> {
    return this.contentOwnersCollectionRef.snapshotChanges().pipe(
      map((contentOwnerDocuments) =>
        contentOwnerDocuments.map((a) => {
          const data = a.payload.doc.data() as ContentOwnerDataModel;
          const id = a.payload.doc.id;
          return { id, ...data } as ContentOwner;
        })
      )
    );
  }

  createContentOwner(
    contentOwner: ContentOwnerDataModel
  ): Observable<ContentOwner> {
    return from(this.contentOwnersCollectionRef.add(contentOwner)).pipe(
      map((docRef) => ({ id: docRef.id, ...contentOwner } as ContentOwner))
    );
  }

  updateContentOwner(contentOwner: ContentOwner): Observable<void> {
    return from(
      this.contentOwnersCollectionRef.doc(contentOwner.id).update({
        ownerName: contentOwner.ownerName,
        ownerSource: contentOwner.ownerSource,
        isActive: contentOwner.isActive,
      })
    );
  }

  deleteContentOwner(id: string): Observable<void> {
    return from(this.contentOwnersCollectionRef.doc(id).delete());
  }
}
