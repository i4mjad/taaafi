import { Component, inject } from '@angular/core';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatDialog } from '@angular/material/dialog';
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';
import { ContentOwner } from '../../../../models/app.model';
import {
  GetContentOwnersAction,
  DeleteContentOwnerAction,
  ToggleContentOwnerStatusAction,
} from '../../../../state/app.actions';
import { AppState } from '../../../../state/app.store';
import { DeleteContentOwnerComponent } from './components/delete-content-owner/delete-content-owner.component';
import { EditContentOwnerComponent } from './components/edit-content-owner/edit-content-owner.component';
import { AddContentOwnerComponent } from './components/add-content-owner/add-content-owner.component';

@Component({
  selector: 'app-content-owners',
  templateUrl: './content-owners.component.html',
  styleUrl: './content-owners.component.scss',
})
export class ContentOwnersComponent {
  contentOwners$: Observable<ContentOwner[]> = inject(Store).select(
    AppState.contentOwners
  );
  tableColumns: string[] = [
    'id',
    'ownerName',
    'ownerSource',
    'enable',
    'actions',
  ];

  owners: ContentOwner[];

  constructor(
    private store: Store,
    private sheet: MatBottomSheet,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.store.dispatch(new GetContentOwnersAction());
    this.contentOwners$.subscribe((data) => {
      if (data.length > 0) {
        this.owners = data;
      }
    });
  }

  onToggleClicked(id: string) {
    this.store.dispatch(new ToggleContentOwnerStatusAction(id));
  }

  openAddBottomSheet(): void {
    this.sheet.open(AddContentOwnerComponent);
  }
  openEditBottomSheet(owner: ContentOwner): void {
    const dialogRef = this.dialog.open(EditContentOwnerComponent, {
      width: '400px',
      data: owner,
    });

    dialogRef.afterClosed().subscribe((result) => {
      this.store.dispatch(new GetContentOwnersAction());
    });
  }
  openDeleteDialog(contentOwner: ContentOwner): void {
    const dialogRef = this.dialog.open(DeleteContentOwnerComponent, {
      width: '400px',
      data: { contentOwner: contentOwner },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result === true) {
        this.store.dispatch(new DeleteContentOwnerAction(contentOwner.id));
      }
      this.store.dispatch(new GetContentOwnersAction());
    });
  }
}
