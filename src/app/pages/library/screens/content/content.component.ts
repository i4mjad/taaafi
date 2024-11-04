import { Component, inject } from '@angular/core';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatDialog } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { Content } from '../../../../models/app.model';

import { AddNewContentComponent } from './components/add-new-content/add-new-content.component';

import { Timestamp } from 'firebase/firestore';
import { EditContentComponent } from './components/edit-content/edit-content.component';
import { DeleteContentComponent } from './components/delete-content/delete-content.component';
import {
  GetContentsAction,
  ToggleContentStatusAction,
  DeleteContentAction,
} from '../../../../state/library/library.actions';
import { AppState } from '../../../../state/library/library.store';

@Component({
  selector: 'app-content',
  templateUrl: './content.component.html',
  styleUrl: './content.component.scss',
})
export class ContentComponent {
  content$: Observable<Content[]> = inject(Store).select(AppState.content);
  tableColumns: string[] = [
    'contentName',
    'contentType',
    'contentCategory',
    'contentLink',
    'contentLanguage',
    'createdAt',
    'updatedAt',
    'updatedBy',
    'isActive',
    'actions',
  ];

  contents: Content[];

  constructor(
    private store: Store,
    private sheet: MatBottomSheet,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.store.dispatch(new GetContentsAction());
    this.content$.subscribe((data) => {
      if (data.length > 0) {
        this.contents = data;
      }
    });
  }

  onToggleClicked(id: string) {
    this.store.dispatch(new ToggleContentStatusAction(id));
  }

  openAddBottomSheet(): void {
    this.sheet.open(AddNewContentComponent);
  }

  openEditBottomSheet(content: Content): void {
    const dialogRef = this.dialog.open(EditContentComponent, {
      width: '400px',
      data: content,
    });
    dialogRef.afterClosed().subscribe((result) => {
      // Handle post-dialog actions here
    });
  }

  openDeleteDialog(content: Content): void {
    const dialogRef = this.dialog.open(DeleteContentComponent, {
      width: '400px',
      data: { content },
    });
    dialogRef.afterClosed().subscribe((result) => {
      if (result === true) {
        this.store.dispatch(new DeleteContentAction(content.id));
      }
    });
  }

  getDateFromTimestamp(date: Timestamp) {
    if (date instanceof Timestamp) {
      return date.toDate();
    } else {
      return date;
    }
  }
}
