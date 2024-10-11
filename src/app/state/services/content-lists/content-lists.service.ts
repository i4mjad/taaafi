import { Injectable } from '@angular/core';
import {
  Content,
  ContentList,
  ContentListDataModel,
} from '../../../models/app.model';
import {
  AngularFirestoreCollection,
  AngularFirestore,
} from '@angular/fire/compat/firestore';
import {
  Observable,
  switchMap,
  combineLatest,
  map,
  from,
  throwError,
  catchError,
  of,
} from 'rxjs';
import { ContentService } from '../content/content.service';

@Injectable({
  providedIn: 'root',
})
export class ContentListService {
  private contentListsRef: AngularFirestoreCollection<ContentListDataModel>;

  constructor(
    private firestore: AngularFirestore,
    private contentService: ContentService
  ) {
    this.contentListsRef =
      this.firestore.collection<ContentListDataModel>('contentLists');
  }

  // Method to get full ContentList with mapped content

  getContentLists(): Observable<ContentList[]> {
    return this.contentListsRef.snapshotChanges().pipe(
      switchMap((snapshots) => {
        if (!snapshots.length) {
          return of([] as ContentList[]);
        }

        const contentListsObservables = snapshots.map((doc) => {
          const data = doc.payload.doc.data() as ContentListDataModel;
          const id = doc.payload.doc.id;

          if (!data.listContentIds || data.listContentIds.length === 0) {
            // If no content IDs, return the ContentList with empty content
            return of({
              id,
              listName: data.listName,
              listDescription: data.listDescription,
              listContent: [],
              isActive: data.isActive,
              isFeatured: data.isFeatured,
            } as ContentList);
          }

          const contentObservables = data.listContentIds.map((contentId) =>
            this.contentService.getContentById(contentId).pipe(
              catchError((error) => {
                console.error(
                  `Error fetching content with ID ${contentId}:`,
                  error
                );
                // Decide how to handle individual content fetch errors
                // Option 1: Exclude the failed content
                return of(null);
                // Option 2: Provide a default Content object
                // return of(defaultContent);
                // Option 3: Propagate the error
                // return throwError(() => error);
              })
            )
          );

          return combineLatest(contentObservables).pipe(
            map((listContent) => {
              // Filter out any nulls if using Option 1 above
              const validContent = listContent.filter(
                (content): content is Content => !!content
              );
              return {
                id,
                listName: data.listName,
                listDescription: data.listDescription,
                listContent: validContent,
                isActive: data.isActive,
                isFeatured: data.isFeatured,
              } as ContentList;
            })
          );
        });

        return combineLatest(contentListsObservables).pipe(
          catchError((error) => {
            console.error('Error fetching content lists:', error);
            return throwError(() => error);
          })
        );
      }),
      catchError((error) => {
        console.error('Error in getContentLists stream:', error);
        return throwError(() => error);
      })
    );
  }

  // Method to create a new content list
  createContentList(contentListData: ContentListDataModel): Observable<void> {
    return from(this.contentListsRef.add(contentListData)).pipe(map(() => {}));
  }

  // Method to update a content list
  updateContentList(
    id: string,
    contentListData: ContentListDataModel
  ): Observable<void> {
    return from(this.contentListsRef.doc(id).update(contentListData));
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
}
