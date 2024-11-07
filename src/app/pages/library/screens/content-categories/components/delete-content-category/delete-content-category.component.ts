import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ContentCategory } from '../../../../../../models/library.model';

@Component({
  selector: 'app-delete-content-category',
  templateUrl: './delete-content-category.component.html',
  styleUrl: './delete-content-category.component.scss',
})
export class DeleteContentCategoryComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentCategoryComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { contentType: ContentCategory }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
