import { Injectable } from '@angular/core';
import {
  AngularFirestore,
  AngularFirestoreCollection,
} from '@angular/fire/compat/firestore';
import { Observable, from, throwError } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';
import {
  ContentCategory,
  ContentCategoryDataModel,
} from '../../../../models/library.model';

@Injectable({
  providedIn: 'root',
})
export class ContentCategoryService {
  private contentCategoriesCollectionsRef: AngularFirestoreCollection<ContentCategoryDataModel>;

  constructor(private firestore: AngularFirestore) {
    this.contentCategoriesCollectionsRef =
      this.firestore.collection<ContentCategoryDataModel>('contentCategories');
  }

  getContentCategories(): Observable<ContentCategory[]> {
    return this.contentCategoriesCollectionsRef.snapshotChanges().pipe(
      map((contentCategoryDocuments) =>
        contentCategoryDocuments.map((a) => {
          const data = a.payload.doc.data() as ContentCategoryDataModel;
          const id = a.payload.doc.id;
          return { id, ...data } as ContentCategory;
        })
      )
    );
  }

  toggleContentCategoryStatus(id: string): Observable<void> {
    const docRef = this.contentCategoriesCollectionsRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentCategoryDataModel;
          const newStatus = !currentData.isActive;
          return from(docRef.update({ isActive: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  createContentCategory(
    contentCategory: ContentCategoryDataModel
  ): Observable<ContentCategory> {
    return from(this.contentCategoriesCollectionsRef.add(contentCategory)).pipe(
      map(
        (docRef) => ({ id: docRef.id, ...contentCategory } as ContentCategory)
      )
    );
  }

  updateContentCategory(contentCategory: ContentCategory): Observable<void> {
    return from(
      this.contentCategoriesCollectionsRef.doc(contentCategory.id).update({
        categoryName: contentCategory.categoryName,
        isActive: contentCategory.isActive,
      })
    );
  }

  deleteContentCategory(id: string): Observable<void> {
    return from(this.contentCategoriesCollectionsRef.doc(id).delete());
  }
}
