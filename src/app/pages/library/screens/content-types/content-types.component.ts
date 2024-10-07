import { Component, inject, OnInit } from '@angular/core';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { AppState } from '../../../../state/app.store';
import {
  DeleteContentTypeAction,
  GetContentTypesAction,
  ToggleContentTypeStatusAction,
} from '../../../../state/app.actions';
import { ContentType } from '../../../../models/app.model';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { AddNewContentTypeComponent } from './componenets/add-new-content-type/add-new-content-type.component';
import { EditContentTypeComponent } from './componenets/edit-content-type/edit-content-type.component';
import { MatDialog } from '@angular/material/dialog';
import { DeleteContentTypeComponent } from './componenets/delete-content-type/delete-content-type.component';

@Component({
  selector: 'app-content-types',
  templateUrl: './content-types.component.html',
  styleUrl: './content-types.component.scss',
})
export class ContentTypesComponent implements OnInit {
  contentTypes$: Observable<ContentType[]> = inject(Store).select(
    AppState.contentTypes
  );
  tableColumns: String[] = ['id', 'contentTypeName', 'enable', 'actions'];

  types: ContentType[];

  constructor(
    private store: Store,
    private sheet: MatBottomSheet,
    private dialog: MatDialog
  ) {}
  ngOnInit(): void {
    this.store.dispatch(new GetContentTypesAction());
    this.contentTypes$.subscribe((data) => {
      if (data.length > 0) {
        this.types = data;
      }
    });
  }

  onToggleClicked(id: string) {
    this.store.dispatch(new ToggleContentTypeStatusAction(id));
  }

  openAddBottomSheet(): void {
    this.sheet.open(AddNewContentTypeComponent);
  }
  openEditBottomSheet(type: ContentType): void {
    const dialogRef = this.dialog.open(EditContentTypeComponent, {
      width: '400px',
      data: type,
    });

    dialogRef.afterClosed().subscribe((result) => {
      // You can handle any post-dialog actions here
    });
  }
  openDeleteDialog(contentType: ContentType): void {
    const dialogRef = this.dialog.open(DeleteContentTypeComponent, {
      width: '400px',
      data: { contentType: contentType }, // Pass the name for confirmation
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result === true) {
        this.store.dispatch(new DeleteContentTypeAction(contentType.id));
      }
    });
  }
}
