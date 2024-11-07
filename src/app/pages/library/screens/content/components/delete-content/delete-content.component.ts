import { Component, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Content } from '../../../../../../models/library.model';

@Component({
  selector: 'app-delete-content',
  templateUrl: './delete-content.component.html',
  styleUrl: './delete-content.component.scss',
})
export class DeleteContentComponent {
  constructor(
    public dialogRef: MatDialogRef<DeleteContentComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { content: Content }
  ) {}

  onCancel(): void {
    this.dialogRef.close(false);
  }

  onConfirm(): void {
    this.dialogRef.close(true);
  }
}
