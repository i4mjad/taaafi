import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ContentType } from '../../../../../../models/app.model';

@Component({
  selector: 'app-delete-content-type',
  templateUrl: './delete-content-type.component.html',
  styleUrl: './delete-content-type.component.scss',
})
export class DeleteContentTypeComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentTypeComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { contentType: ContentType }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
