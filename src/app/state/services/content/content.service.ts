import { Injectable } from '@angular/core';
import {
  AngularFirestore,
  AngularFirestoreCollection,
} from '@angular/fire/compat/firestore';
import {
  Observable,
  map,
  from,
  switchMap,
  throwError,
  combineLatest,
  forkJoin,
} from 'rxjs';
import {
  ContentDateModel,
  Content,
  ContentCategory,
  ContentCategoryDataModel,
  ContentOwner,
  ContentOwnerDataModel,
  ContentType,
  ContentTypeDataModel,
} from '../../../models/app.model';

@Injectable({
  providedIn: 'root',
})
export class ContentService {
  private contentCollectionsRef: AngularFirestoreCollection<ContentDateModel>;
  private contentTypesRef: AngularFirestoreCollection<ContentTypeDataModel>;
  private contentCategoriesRef: AngularFirestoreCollection<ContentCategoryDataModel>;
  private contentOwnersRef: AngularFirestoreCollection<ContentOwnerDataModel>;

  constructor(private firestore: AngularFirestore) {
    this.contentCollectionsRef =
      this.firestore.collection<ContentDateModel>('content');
    this.contentTypesRef =
      this.firestore.collection<ContentTypeDataModel>('contentTypes');
    this.contentCategoriesRef =
      this.firestore.collection<ContentCategoryDataModel>('contentCategories');
    this.contentOwnersRef =
      this.firestore.collection<ContentOwnerDataModel>('contentOwners');
  }

  // Method to get the content type details by id
  getContentTypeById(contentTypeId: string): Observable<ContentType> {
    console.log(contentTypeId);

    return this.contentTypesRef
      .doc(contentTypeId)
      .snapshotChanges()
      .pipe(
        map((doc) => {
          const data = doc.payload.data() as ContentTypeDataModel;
          const contentType = { id: doc.payload.id, ...data };
          console.log('this is cake', contentType);
          return contentType as ContentType;
        })
      );
  }

  // Method to get the content category details by id
  getContentCategoryById(
    contentCategoryId: string
  ): Observable<ContentCategory> {
    return this.contentCategoriesRef
      .doc(contentCategoryId)
      .snapshotChanges()
      .pipe(
        map((doc) => {
          const data = doc.payload.data() as ContentCategoryDataModel;
          return { id: doc.payload.id, ...data } as ContentCategory;
        })
      );
  }

  // Method to get the content owner details by id
  getContentOwnerById(contentOwnerId: string): Observable<ContentOwner> {
    return this.contentOwnersRef
      .doc(contentOwnerId)
      .snapshotChanges()
      .pipe(
        map((doc) => {
          const data = doc.payload.data() as ContentOwnerDataModel;
          return { id: doc.payload.id, ...data } as ContentOwner;
        })
      );
  }

  // Method to get the contents with all their related documents
  getContents(): Observable<Content[]> {
    return this.contentCollectionsRef.snapshotChanges().pipe(
      switchMap((contentDocuments) => {
        // For each content document, get the related content type, category, and owner
        const contentObservables = contentDocuments.map((contentDoc) => {
          const data = contentDoc.payload.doc.data() as ContentDateModel;
          const id = contentDoc.payload.doc.id;

          // Retrieve related documents
          const contentType$ = this.getContentTypeById(data.contentTypeId);
          const contentCategory$ = this.getContentCategoryById(
            data.contentCategoryId
          );
          const contentOwner$ = this.getContentOwnerById(data.contentOwnerId);

          return forkJoin([contentType$, contentCategory$, contentOwner$]).pipe(
            map(([contentType, contentCategory, contentOwner]) => {
              console.log(contentType, contentCategory, contentOwner);

              return {
                id,
                contentName: data.contentName,
                contentType,
                contentCategory,
                contentOwner,
                contentLink: data.contentLink,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt,
                updatedBy: data.updatedBy,
                isActive: data.isActive,
              } as Content;
            })
          );
        });

        // Return all content after fetching related details
        return combineLatest(contentObservables);
      })
    );
  }

  // Method to toggle the active status of content
  toggleContentStatus(id: string): Observable<void> {
    const docRef = this.contentCollectionsRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentDateModel;
          const newStatus = !currentData.isActive;
          return from(docRef.update({ isActive: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  // Method to create content with only the necessary IDs
  createContent(content: ContentDateModel): Observable<Content> {
    return from(this.contentCollectionsRef.add(content)).pipe(
      switchMap((docRef) => {
        // After the content is created, retrieve the full content object with related documents
        return this.getContentById(docRef.id);
      })
    );
  }

  getContentById(contentId: string): Observable<Content> {
    return this.contentCollectionsRef
      .doc(contentId)
      .snapshotChanges()
      .pipe(
        switchMap((contentDoc) => {
          if (!contentDoc.payload.exists) {
            return throwError(() => new Error('Content not found'));
          }

          const data = contentDoc.payload.data() as ContentDateModel;
          const id = contentDoc.payload.id;

          // Retrieve related documents using their IDs
          const contentType$ = this.getContentTypeById(data.contentTypeId);
          const contentCategory$ = this.getContentCategoryById(
            data.contentCategoryId
          );
          const contentOwner$ = this.getContentOwnerById(data.contentOwnerId);

          // Combine observables to create the full content object
          return forkJoin([contentType$, contentCategory$, contentOwner$]).pipe(
            map(([contentType, contentCategory, contentOwner]) => {
              return {
                id,
                contentName: data.contentName,
                contentType,
                contentCategory,
                contentOwner,
                contentLink: data.contentLink,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt,
                updatedBy: data.updatedBy,
                isActive: data.isActive,
              } as Content;
            })
          );
        })
      );
  }

  // Method to update the content, including its related document IDs
  updateContent(content: Content): Observable<void> {
    return from(
      this.contentCollectionsRef.doc(content.id).update({
        contentName: content.contentName,
        contentTypeId: content.contentType.id, // Only store the ID
        contentCategoryId: content.contentCategory.id, // Only store the ID
        contentOwnerId: content.contentOwner.id, // Only store the ID
        contentLink: content.contentLink,
        updatedAt: new Date(),
        updatedBy: content.updatedBy,
        isActive: content.isActive,
      })
    );
  }

  // Method to delete content
  deleteContent(id: string): Observable<void> {
    return from(this.contentCollectionsRef.doc(id).delete());
  }
}
