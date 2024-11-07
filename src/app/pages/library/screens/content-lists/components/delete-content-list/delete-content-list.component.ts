import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Content, ContentList } from '../../../../../../models/library.model';

@Component({
  selector: 'app-delete-content-list',
  templateUrl: './delete-content-list.component.html',
  styleUrl: './delete-content-list.component.scss',
})
export class DeleteContentListComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentListComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { contentList: ContentList }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
