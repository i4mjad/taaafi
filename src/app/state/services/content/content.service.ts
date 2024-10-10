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
  take,
  catchError,
  of,
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
import { AuthService } from '../../../services/auth.service';

@Injectable({
  providedIn: 'root',
})
export class ContentService {
  private contentCollectionsRef: AngularFirestoreCollection<ContentDateModel>;
  private contentTypesRef: AngularFirestoreCollection<ContentTypeDataModel>;
  private contentCategoriesRef: AngularFirestoreCollection<ContentCategoryDataModel>;
  private contentOwnersRef: AngularFirestoreCollection<ContentOwnerDataModel>;

  constructor(
    private firestore: AngularFirestore,
    private authService: AuthService
  ) {
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
    return this.contentTypesRef
      .doc(contentTypeId)
      .snapshotChanges()
      .pipe(
        map((doc) => {
          const data = doc.payload.data() as ContentTypeDataModel;
          const contentType = { id: doc.payload.id, ...data };
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
        const contentObservables = contentDocuments.map((contentDoc) => {
          const data = contentDoc.payload.doc.data() as ContentDateModel;
          const id = contentDoc.payload.doc.id;

          return this.getRelatedData(data, id);
        });

        return combineLatest(contentObservables);
      }),
      catchError((error) => {
        console.error('Error fetching contents:', error);
        return of([]); // Return an empty array if an error occurs
      })
    );
  }

  private getRelatedData(
    data: ContentDateModel,
    id: string
  ): Observable<Content> {
    const contentType$ = this.getContentTypeById(data.contentTypeId).pipe(
      take(1)
    );
    const contentCategory$ = this.getContentCategoryById(
      data.contentCategoryId
    ).pipe(take(1));
    const contentOwner$ = this.getContentOwnerById(data.contentOwnerId).pipe(
      take(1)
    );

    return forkJoin([contentType$, contentCategory$, contentOwner$]).pipe(
      map(
        ([contentType, contentCategory, contentOwner]) =>
          ({
            id,
            contentName: data.contentName,
            contentType,
            contentCategory,
            contentOwner,
            contentLink: data.contentLink,
            createdAt: data.createdAt ? data.createdAt : new Date(), // Ensure a valid Date object
            updatedAt: data.updatedAt ? data.updatedAt : new Date(), // Ensure a valid Date object
            updatedBy: data.updatedBy || '', // Fallback for undefined values
            isActive: data.isActive,
          } as Content)
      ),
      catchError((error) => {
        console.error('Error fetching related data:', error);

        // Return a default Content object if an error occurs
        return of({
          id,
          contentName: data.contentName,
          contentType: {} as ContentType, // Return empty objects or defaults
          contentCategory: {} as ContentCategory,
          contentOwner: {} as ContentOwner,
          contentLink: data.contentLink || '',
          createdAt: new Date(),
          updatedAt: new Date(),
          updatedBy: '',
          isActive: false,
        } as Content);
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
  updateContent(
    contentId: string,
    contentData: ContentDateModel
  ): Observable<void> {
    return from(
      this.contentCollectionsRef.doc(contentId).update({
        contentName: contentData.contentName,
        contentTypeId: contentData.contentTypeId, // Only store the ID
        contentCategoryId: contentData.contentCategoryId, // Only store the ID
        contentOwnerId: contentData.contentOwnerId, // Only store the ID
        contentLink: contentData.contentLink,
        updatedAt: new Date(),
        updatedBy: contentData.updatedBy, // Ensure you pass the user ID
        isActive: contentData.isActive,
      })
    );
  }

  // Method to delete content
  deleteContent(id: string): Observable<void> {
    return from(this.contentCollectionsRef.doc(id).delete());
  }
}
