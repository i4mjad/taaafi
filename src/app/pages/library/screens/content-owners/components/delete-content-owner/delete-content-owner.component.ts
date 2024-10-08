import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ContentOwner } from '../../../../../../models/app.model';

@Component({
  selector: 'app-delete-content-owner',
  templateUrl: './delete-content-owner.component.html',
  styleUrl: './delete-content-owner.component.scss',
})
export class DeleteContentOwnerComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentOwnerComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { contentOwner: ContentOwner }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onDelete(): void {
    this.dialogRef.close(true);
  }
}
