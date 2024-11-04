import { Component, OnInit, inject } from '@angular/core';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatDialog } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import {
  ContentList,
  ContentListViewModel,
} from '../../../../models/app.model';

import { AddNewContentListComponent } from '../content-lists/components/add-new-content-list/add-new-content-list.component';
import { DeleteContentListComponent } from '../content-lists/components/delete-content-list/delete-content-list.component';
import { EditContentListComponent } from '../content-lists/components/edit-content-list/edit-content-list.component';
import {
  GetContentListsAction,
  ToggleContentListStatusAction,
  ToggleContentListFeaturedAction,
  DeleteContentListAction,
} from '../../../../state/library/library.actions';
import { LibraryState } from '../../../../state/library/library.store';

@Component({
  selector: 'app-content-lists',
  templateUrl: './content-lists.component.html',
  styleUrls: ['./content-lists.component.scss'],
})
export class ContentListsComponent implements OnInit {
  contentLists$: Observable<ContentListViewModel[]> = inject(Store).select(
    LibraryState.contentLists
  );
  tableColumns: String[] = [
    'id',
    'listName',
    'contentCount',
    'isActive',
    'isFeatured',
    'actions',
  ];

  contentLists: ContentListViewModel[];

  constructor(private store: Store, private dialog: MatDialog) {}

  ngOnInit(): void {
    this.store.dispatch(new GetContentListsAction());
    this.contentLists$.subscribe((data) => {
      if (data.length > 0) {
        this.contentLists = data;
      } else {
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
    this.dialog.open(AddNewContentListComponent, {
      width: '90%',
    });
  }

  // Open the Edit Content List Dialog
  openEditBottomSheet(contentList: ContentList): void {
    const dialogRef = this.dialog.open(EditContentListComponent, {
      width: '90%',
      height: '90%',

      data: {
        id: contentList.id,
      },
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
