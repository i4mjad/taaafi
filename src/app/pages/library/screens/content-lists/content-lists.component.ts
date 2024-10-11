import { Component, OnInit, inject } from '@angular/core';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatDialog } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { ContentList } from '../../../../models/app.model';
import {
  GetContentListsAction,
  ToggleContentListStatusAction,
  ToggleContentListFeaturedAction,
  DeleteContentListAction,
} from '../../../../state/app.actions';
import { AppState } from '../../../../state/app.store';
import { AddNewContentListComponent } from '../content-lists/components/add-new-content-list/add-new-content-list.component';
import { DeleteContentListComponent } from '../content-lists/components/delete-content-list/delete-content-list.component';
import { EditContentListComponent } from '../content-lists/components/edit-content-list/edit-content-list.component';

@Component({
  selector: 'app-content-lists',
  templateUrl: './content-lists.component.html',
  styleUrls: ['./content-lists.component.scss'],
})
export class ContentListsComponent implements OnInit {
  contentLists$: Observable<ContentList[]> = inject(Store).select(
    AppState.contentLists
  );
  tableColumns: String[] = [
    'id',
    'listName',
    'contentCount',
    'isActive',
    'isFeatured',
    'actions',
  ];

  contentLists: ContentList[];

  constructor(
    private store: Store,
    private sheet: MatBottomSheet,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.store.dispatch(new GetContentListsAction());
    this.contentLists$.subscribe((data) => {
      console.log('Data received in component:', data); // Ensure data is received in the component
      if (data.length > 0) {
        console.log('Content lists available:', data);
        this.contentLists = data;
      } else {
        console.log('No content lists available');
      }
    });
  }

  // Toggle the active status
  onToggleActive(id: string) {
    this.store.dispatch(new ToggleContentListStatusAction(id));
  }

  // Toggle the featured status
  onToggleFeatured(id: string) {
    this.store.dispatch(new ToggleContentListFeaturedAction(id));
  }

  // Open the Add New Content List Bottom Sheet
  openAddBottomSheet(): void {
    this.sheet.open(AddNewContentListComponent);
  }

  // Open the Edit Content List Dialog
  openEditBottomSheet(contentList: ContentList): void {
    const dialogRef = this.dialog.open(EditContentListComponent, {
      width: '400px',
      data: contentList,
    });

    dialogRef.afterClosed().subscribe((result) => {
      // Handle post-dialog actions
    });
  }

  // Open the Delete Confirmation Dialog
  openDeleteDialog(contentList: ContentList): void {
    const dialogRef = this.dialog.open(DeleteContentListComponent, {
      width: '400px',
      data: { contentList: contentList }, // Pass the content list for confirmation
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result === true) {
        this.store.dispatch(new DeleteContentListAction(contentList.id));
      }
    });
  }
}
