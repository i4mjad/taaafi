import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ContentType } from '../../../../../../models/app.model';

@Component({
  selector: 'app-delete-content-category',
  templateUrl: './delete-content-category.component.html',
  styleUrl: './delete-content-category.component.scss',
})
export class DeleteContentCategoryComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentCategoryComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { contentType: ContentType }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false); // Close the dialog without deleting
  }

  onConfirm(): void {
    this.dialogRef.close(true); // Confirm the deletion
  }
}
