import { Injectable } from '@angular/core';
import {
  Content,
  ContentCategory,
  ContentCategoryDataModel,
  ContentDateModel,
  ContentList,
  ContentListDataModel,
  ContentListViewModel,
  ContentOwner,
  ContentOwnerDataModel,
  ContentType,
  ContentTypeDataModel,
} from '../../../../models/library.model';
import {
  AngularFirestoreCollection,
  AngularFirestore,
} from '@angular/fire/compat/firestore';
import {
  Observable,
  switchMap,
  map,
  from,
  throwError,
  tap,
  catchError,
  forkJoin,
  of,
} from 'rxjs';
import { ContentService } from '../content/content.service';

@Injectable({
  providedIn: 'root',
})
export class ContentListService {
  private contentListsRef: AngularFirestoreCollection<ContentListDataModel>;
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
    this.contentListsRef =
      this.firestore.collection<ContentListDataModel>('contentLists');
  }

  getContentLists(): Observable<ContentListViewModel[]> {
    return this.contentListsRef.snapshotChanges().pipe(
      tap((snapshots) => {}),
      switchMap((snapshots) => {
        if (snapshots.length === 0) {
          console.warn('No content lists found');
          return of([]); // Handle case when no content lists are found
        }

        // Map each snapshot to a ContentListViewModel
        const contentListViewModels = snapshots.map((doc) => {
          const data = doc.payload.doc.data() as ContentListDataModel;
          const id = doc.payload.doc.id;

          return {
            id,
            listName: data.listName,
            listDescription: data.listDescription,
            listContentCount: data.listContentIds.length, // Use length for content count
            contentListIconName: data.contentListIconName, // Add this line
            isActive: data.isActive,
            isFeatured: data.isFeatured,
          } as ContentListViewModel;
        });

        // Return the array of ContentListViewModels
        return of(contentListViewModels);
      }),
      catchError((error) => {
        console.error('Error fetching content lists:', error);
        return of([]); // Return an empty array if an error occurs
      })
    );
  }

  getContentListById(id: string): Observable<ContentList> {
    return this.contentListsRef
      .doc(id)
      .snapshotChanges()
      .pipe(
        switchMap((doc) => {
          if (!doc.payload.exists) {
            console.warn('Content list not found with id:', id);
            return of({
              id,
              listName: '',
              listDescription: '',
              listContent: [], // Empty listContent if not found
              contentListIconName: '', // Add this line
              isActive: false,
              isFeatured: false,
            } as ContentList); // Return an empty ContentList object if not found
          }

          const data = doc.payload.data() as ContentListDataModel;

          if (data.listContentIds.length === 0) {
            console.warn(
              'No content IDs for this content list:',
              data.listName
            );
            return of({
              id: doc.payload.id,
              listName: data.listName,
              listDescription: data.listDescription,
              listContent: [], // Empty listContent if no contentIds
              contentListIconName: data.contentListIconName, // Add this line
              isActive: data.isActive,
              isFeatured: data.isFeatured,
            } as ContentList);
          }

          // Fetch associated content items using listContentIds
          return forkJoin(
            data.listContentIds.map((contentId) =>
              this.getContentById(contentId)
            )
          ).pipe(
            map((listContent) => {
              const validListContent = listContent.filter(
                (content) => content !== null
              );

              return {
                id: doc.payload.id,
                listName: data.listName,
                listDescription: data.listDescription,
                listContent: validListContent,
                contentListIconName: data.contentListIconName, // Add this line
                isActive: data.isActive,
                isFeatured: data.isFeatured,
              } as ContentList;
            })
          );
        }),
        catchError((error) => {
          console.error('Error fetching content list by id:', error);
          return of({
            id,
            listName: '',
            listDescription: '',
            listContent: [], // Return an empty listContent on error
            contentListIconName: '', // Add this line
            isActive: false,
            isFeatured: false,
          } as ContentList); // Return an empty ContentList object on error
        })
      );
  }

  // Method to create a new content list
  createContentList(contentListData: ContentListDataModel): Observable<void> {
    const docRef = this.contentListsRef.doc();
    const id = docRef.ref.id;
    return from(docRef.set({ ...contentListData, id })).pipe(map(() => {}));
  }

  // Method to update a content list
  updateContentList(
    id: string,
    contentListData: ContentListDataModel
  ): Observable<void> {
    return from(
      this.contentListsRef.doc(id).update({
        listName: contentListData.listName,
        listDescription: contentListData.listDescription,
        listContentIds: contentListData.listContentIds,
        contentListIconName: contentListData.contentListIconName,
        isActive: contentListData.isActive,
        isFeatured: contentListData.isFeatured,
      })
    );
  }

  // Method to delete a content list
  deleteContentList(id: string): Observable<void> {
    return from(this.contentListsRef.doc(id).delete());
  }

  // Method to toggle the active status of a content list
  toggleContentListStatus(id: string): Observable<void> {
    const docRef = this.contentListsRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentListDataModel;
          const newStatus = !currentData.isActive;
          return from(docRef.update({ isActive: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  // Method to toggle the featured status of a content list
  toggleContentListFeatured(id: string): Observable<void> {
    const docRef = this.contentListsRef.doc(id);
    return from(docRef.get()).pipe(
      switchMap((doc) => {
        if (doc.exists) {
          const currentData = doc.data() as ContentListDataModel;
          const newStatus = !currentData.isFeatured;
          return from(docRef.update({ isFeatured: newStatus }));
        } else {
          return throwError(() => new Error('Document does not exist'));
        }
      })
    );
  }

  // Fetch content type by ID without using observables
  private async getContentTypeById(
    contentTypeId: string
  ): Promise<ContentType | null> {
    try {
      const doc = await this.contentTypesRef
        .doc(contentTypeId)
        .get()
        .toPromise();
      if (!doc?.exists) {
        console.warn('Content type not found for ID:', contentTypeId);
        return null;
      }
      const data = doc.data() as ContentTypeDataModel;
      return { id: doc.id, ...data } as ContentType;
    } catch (error) {
      console.error('Error fetching content type:', error);
      return null;
    }
  }

  // Fetch content category by ID without using observables
  private async getContentCategoryById(
    contentCategoryId: string
  ): Promise<ContentCategory | null> {
    try {
      const doc = await this.contentCategoriesRef
        .doc(contentCategoryId)
        .get()
        .toPromise();
      if (!doc?.exists) {
        console.warn('Content category not found for ID:', contentCategoryId);
        return null;
      }
      const data = doc.data() as ContentCategoryDataModel;
      return { id: doc.id, ...data } as ContentCategory;
    } catch (error) {
      console.error('Error fetching content category:', error);
      return null;
    }
  }

  // Fetch content owner by ID without using observables
  private async getContentOwnerById(
    contentOwnerId: string
  ): Promise<ContentOwner | null> {
    try {
      const doc = await this.contentOwnersRef
        .doc(contentOwnerId)
        .get()
        .toPromise();
      if (!doc?.exists) {
        console.warn('Content owner not found for ID:', contentOwnerId);
        return null;
      }
      const data = doc.data() as ContentOwnerDataModel;
      return { id: doc.id, ...data } as ContentOwner;
    } catch (error) {
      console.error('Error fetching content owner:', error);
      return null;
    }
  }

  private async getContentById(contentId: string): Promise<Content | null> {
    try {
      const contentDoc = await this.contentCollectionsRef
        .doc(contentId)
        .get()
        .toPromise();

      if (!contentDoc?.exists) {
        console.error('Content not found for ID:', contentId);
        return null; // Return null if content doesn't exist
      }

      const data = contentDoc.data() as ContentDateModel;
      const id = contentDoc.id;

      // Fetch related documents (non-observable)
      const contentType = await this.getContentTypeById(data.contentTypeId);
      const contentCategory = await this.getContentCategoryById(
        data.contentCategoryId
      );
      const contentOwner = await this.getContentOwnerById(data.contentOwnerId);

      // Combine the data into a full content object
      const content = {
        id,
        contentName: data.contentName,
        contentType: contentType || {
          id: '',
          contentTypeName: 'Unknown',
          isActive: false,
        },
        contentCategory: contentCategory || {
          id: '',
          categoryName: 'Unknown',
          isActive: false,
        },
        contentOwner: contentOwner || { id: '', ownerName: 'Unknown' },
        contentLink: data.contentLink,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        updatedBy: data.updatedBy,
        isActive: data.isActive,
      } as Content;

      return content;
    } catch (error) {
      console.error('Error fetching content:', error);
      return null;
    }
  }
}
